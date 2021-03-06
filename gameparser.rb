# coding: utf-8

require './rdparse'
require './classes'

# $variables = [{}] # rekommenderas på det sättet för att kunna
                    # hantera scope

# $scope = 0
# $variables = {}
# $functions = {}


$current_scope = 0
$variables = [Hash.new()]
$functions = Hash.new()

# 1) $variables= {"global" => {}, "test" => {}}
# 2) $variables = {"global" => {}, "test" => {"i" => Variable, "k" => Variable}}

class GameLanguage

  def initialize

    @gameParser = Parser.new("game language") do

      token(/#.*/) # removes comment
      token(/\s+/) # removes whitespaces
      token(/^\d+/) {|m| m.to_i} # returns integers

      token(/false/) {|m|m}
      token(/true/) {|m| m }
      token(/or/) {|m| m }
      token(/and/) {|m| m }
      token(/not/) {|m| m }
      token(/def/) {|m| m }
      token(/write/) {|m| m }
      token(/read/) {|m| m }
      token(/if/) {|m| m }
      token(/else/) {|m| m }
      token(/case/) {|m| m }
      token(/while/) {|m| m }
      token(/for/) {|m| m }
      token(/in/) {|m| m }

      token(/<=/){|m| CompOp.new(m) }
      token(/==/){|m| CompOp.new(m) }
      token(/!=/){|m| CompOp.new(m) }
      token(/</){|m| CompOp.new(m)  }
      token(/>=/){|m| CompOp.new(m) }
      token(/>/){|m| CompOp.new(m)  }

      # returns variable/function names as an Identifier object
      token(/^[a-zA-Z][a-zA-Z_0-9]*/) {|m| Identifier.new(m) }

      token(/((?<![\\])['"])((?:.(?!(?<![\\])\1))*.?)\1/) do |m|
        m = m[1...-1]
        LiteralString.new(m)
      end # returns a LiteralString object

      token(/./) {|m| m } # returns rest like (, {, =, < etc as string

      start :prog do
        match(:comps) {|m| Comps.new(m).evaluate() unless m.class == nil }
      end

      rule :comps do
        match(:comps, :comp) {|m, n| m + Array(Comp.new(n)) }
        match(:comp) {|m| Array(Comp.new(m)) }
      end

      rule :comp do
        match(:definition) {|m| Definition.new(m) }
        match(:statement) {|m| Statement.new(m) }
      end

      rule :definition do
        match(:type)
        match(:event)
        match(:function_def)
      end

      rule :function_def do
        match("def", Identifier, "(", :params, ")", :block) do
          |_, func, _, params, _, block|
          $functions[func.name] = Function.new(params, block)
        end
      end

      rule :params do
        match(:params, :param) {|m, n| m + Array(n) }
        match(:param) {|m| Array(m)}
        match(:empty)  {|m| [] }
      end

      rule :param do
        match(Identifier) {|m| m}
      end

      rule :block do
        match("{", :statements, "}") {|_, m, _| Block.new(m)}
      end

      rule :function_call do
        match(Identifier, "(", :values, ")") do |idn, _, args, _|
          # puts "#{idn.name}\t#{args}"
          # puts $functions
          FunctionCall.new(idn, args)
          #$functions[m.name].evaluate(arguments)
        end

        match("write", "(", LiteralString, ")") {|_, _, s, _| Write.new(s)}
        match("write", "(", Identifier, ")") do |_, _, i, _|
          Write.new($variables[$current_scope][i.name])
        end
        match("write", "(", ")") { Write.new("")}
        match("read", "(", LiteralString, ")") {|_, _, m, _|Read.new(m)}
      end

      rule :statements do
        match(:statements, :statement) {|m, n| m + Array(n) }
        match(:statement) {|m| Array(m)}
      end

      rule :statement do
        match(:condition)
        #match(:loop)
        match(:assignment)
        match(:value)
      end


      rule :assignsments do
        match(:assignsments, :assignment)
        match(:assignment)
      end

      rule :assignment do
        match(Identifier, "=", :value) do |m,  _, n|
          Assignment.new(m.name, n)
        end
      end

      rule :values do
        match(:values, ",", :value) {|m, _, n| m + Array(n)}
        match(:value) {|m| Array(m)}
        match(:empty)  {|m| [] }
      end

      rule :value do
        match(LiteralString)
        match(:array)
        match(:exp)
      end

      rule :array do
        match("[", :values, "]") {|_, v, _| Arry.new(v)}
        match("[", "]") { Arry.new([]) }
      end

      rule :exp do
        match(:log_exp) {|e| e}

      end

      rule :log_exp do
        match(:bool_exp, "and", :log_exp) {|lhs, _, rhs| And.new(lhs, rhs) }
        match(:bool_exp, "or", :log_exp) {|lhs, _, rhs| Or.new(lhs, rhs) }
        match("not", :log_exp) {|_, m, _| Not.new(m) }
        match(:bool_exp) {|m| m}
      end

      rule :bool_exp do
         match(:math_exp, CompOp, :math_exp) do |lhs, c, rhs|
          case c.op
          when "<=" then
            LessEqual.new(lhs, rhs)
          when "==" then
            Equal.new(lhs, rhs)
          when "!=" then
            NotEqual.new(lhs, rhs)
          when "<" then
            Less.new(lhs, rhs)
          when ">=" then
            GreaterEqual.new(lhs, rhs)
          when ">" then
            Greater.new(lhs, rhs)
          end
         end

        match(:bool_val, CompOp, :bool_val) do |lhs, c, rhs|
          case c.op
          when "==" then
            Equal.new(lhs, rhs)
          when "!=" then
            NotEqual.new(lhs, rhs)
          end
        end

        match(:bool_val) {|m| m }

      end

      rule :bool_val do
        match("true") {|b| LiteralBool.new(b) }
        match("false") {|b| LiteralBool.new(b) }
        match(:math_exp)
      end

      rule :math_exp do
        match(:math_exp, "+", :term) {|m, _, n| Addition.new(m, n) }
        match(:math_exp, "-", :term) {|m, _, n| Subtraction.new(m, n) }
        match(:term) {|m| m}
      end

      rule :term do
        match(:term, "*", :factor) {|m, _, n| Multiplication.new(m, n) }
        match(:term, "/", :factor) {|m, _, n| Division.new(m, n) }
        match(:factor) {|m| m}
      end

      rule :factor do
        match(Integer) {|m| LiteralInteger.new(m) }
        match("-", Integer) {|_, m| LiteralInteger.new(-m) }
        match("+", Integer) {|_, m| LiteralInteger.new(m) }
        match("+", "(", :math_exp , ")"){|_, _, m, _| m }
        match("-", "(", :math_exp , ")"){|_, _, m, _| Multiplication.new(m, -1) }
        match("(", :log_exp , ")"){|_, m, _| m }
        match(:function_call)
        match(Identifier) {|m| IdentifierNode.new(m)}
      end

      rule :condition do
        match(:if)
        match(:switch)
      end

      rule :if do
        match("if", :exp, :block, "else", :block) {|_, e, b, _, eb| If.new(e, b, eb)}
        match("if", :exp, :block) {|_, e, b| If.new(e, b)}
      end

      rule :switch do
        match("case", Identifier, :block) {|_, id, b|Case.new(id, b)}
      end

      rule :loop do
        match("while", :exp, :block) {|_, e, b| While.new(e, b)}
        match("for", Identifier, "in", :array, :block) {|_, i, _, a, b| For.new(i, a, b)}
      end
    end

# ============================================================
# Parser end
# ============================================================


    def done(str)
      ["quit","exit","bye",""].include?(str.chomp)
    end
    def parse_string(str)
      log(false)
      @gameParser.parse(str)
    end
    def parse()
      print "[gameParser] "
      #str = File.read(file)
      str = gets
      if done(str) then
        puts "Bye."
      else
        puts "=> #{@gameParser.parse str}"
        parse
      end
    end

    def log(state = true)
      if state
        @gameParser.logger.level = Logger::DEBUG
      else
        @gameParser.logger.level = Logger::WARN
      end
    end
  end
end

if __FILE__ == $0
  GameLanguage.new.parse()
end

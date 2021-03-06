# coding: utf-8
require './gameparser'
require 'test/unit'

class FunctionTest < Test::Unit::TestCase
  def test1()
    gp = GameLanguage.new

    code = "def test(i)
            {
             k = i + p
             k
            }
            "

    assert_equal(nil, gp.parse_string(code))
  end

  def test2()
    gp = GameLanguage.new

    code = "def test(i)
            {
             k = i + 12
             k
            }
            "

    assert_equal(nil, gp.parse_string(code))
    assert_equal(14, gp.parse_string("test(2)"))
    assert_equal(32, gp.parse_string("test(20)"))
    assert_equal(13, gp.parse_string("test(2 / 2)"))
  end

  def test3()
    gp = GameLanguage.new

    code = "def test1(i)
            {
             k = i + 12
             k
            }
            def test2(j)
            {
             p = ( j * 2 ) - 2
             p
            }
            def test3(x)
            {
             y = ( x * 2 ) - 2
             y
             x
            }
            "
    assert_equal(nil, gp.parse_string(code))
    assert_equal(14, gp.parse_string("test1(2)"))
    assert_equal(2, gp.parse_string("test2(2)"))
    assert_equal(-4, gp.parse_string("test2(-1)"))
    assert_equal(30, gp.parse_string("test3(30)"))
  end

  def test4()
    gp = GameLanguage.new

    code = "def test1(i)
            {
             k = i + 12
             k
            }
            def test2(j)
            {
             t = test1(j)
             t = t + 5
             t
            }
            "
    assert_equal(nil, gp.parse_string(code))
    assert_equal(20, gp.parse_string("test1(8)"))
    assert_equal(25, gp.parse_string("test2(8)"))
    assert_equal(17, gp.parse_string("test2(0)"))

  end

  def test5()
    gp = GameLanguage.new

    code = "def test1(i)
            {
             k = i + 12
             k
            }
            def test2(j)
            {
             t = 6 * test1(j)
             t
            }
            "
    assert_equal(nil, gp.parse_string(code))
    assert_equal(72, gp.parse_string("test2(0)"))
    assert_equal(60, gp.parse_string("test2(-2)"))
    assert_equal(0, gp.parse_string("test2(-12)"))

  end

  def test_recursion1()
    gp = GameLanguage.new

    code = "def rec(x)
    {
      if x > 10
        {
          x
        }
      else
        {
          rec (x+3)
        }
      }
      rec(0)"
    assert_equal(12, gp.parse_string(code))
  end

  def test_recursion2()
    gp = GameLanguage.new

    code = "def rec(x)
    {
      counter = 0
      if x == 5
        {
          counter
        }
      else
        {
          counter = counter + 1
          counter + rec (x+1)
        }
      }
      rec(0)"
    assert_equal(5, gp.parse_string(code))
    assert_equal(0, gp.parse_string("rec(5)"))
  end


end

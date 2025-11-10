require_relative '../test_helper'
require 'rapicco/pdf/ansi_parser'

class TestAnsiParser < Test::Unit::TestCase
  def setup
    @parser = Rapicco::PDF::AnsiParser.new(cols: 80, rows: 24)
  end

  def test_initialize
    assert_equal 80, @parser.cols
    assert_equal 24, @parser.rows
    assert_equal 24, @parser.screen.size
    assert_equal 80, @parser.screen[0].size
  end

  def test_parse_simple_text
    @parser.parse("Hello")
    assert_equal 'H', @parser.screen[0][0][:char]
    assert_equal 'e', @parser.screen[0][1][:char]
    assert_equal 'l', @parser.screen[0][2][:char]
    assert_equal 'l', @parser.screen[0][3][:char]
    assert_equal 'o', @parser.screen[0][4][:char]
  end

  def test_parse_newline
    @parser.parse("Hello\nWorld")
    assert_equal 'H', @parser.screen[0][0][:char]
    assert_equal 'W', @parser.screen[1][0][:char]
  end

  def test_parse_cursor_home
    @parser.parse("ABC\e[HXY")
    assert_equal 'X', @parser.screen[0][0][:char]
    assert_equal 'Y', @parser.screen[0][1][:char]
  end

  def test_parse_cursor_position
    @parser.parse("\e[3;5HX")
    assert_equal 'X', @parser.screen[2][4][:char]
  end

  def test_parse_color_red
    @parser.parse("\e[31mRED")
    assert_equal [1.0, 0.0, 0.0], @parser.screen[0][0][:fg]
  end

  def test_parse_color_reset
    @parser.parse("\e[31mRED\e[0mNORMAL")
    assert_equal [1.0, 0.0, 0.0], @parser.screen[0][0][:fg]
    assert_nil @parser.screen[0][3][:fg]
  end

  def test_reset_screen
    @parser.parse("Hello")
    @parser.reset_screen
    assert_equal ' ', @parser.screen[0][0][:char]
  end
end

defmodule Olap.Formula.ParserTest do
  use ExUnit.Case, async: true
  alias Olap.Formula.Parser

  defp assert_parse(input, expected_ast) do
    case Parser.parse(input) do
      {:ok, ast} -> assert(ast == expected_ast)
      {:error, reason} -> flunk("Failed to parse `#{input}`: #{inspect(reason)}")
    end
  end

  defp assert_parse_error(input) do
    case Parser.parse(input) do
      {:ok, _ast} -> flunk("Expected to fail to parse `#{input}`")
      {:error, _reason} -> :ok
    end
  end

  test "field" do
    assert_parse("field", {:field, ["field"]})
    assert_parse("foo123", {:field, ["foo123"]})
    assert_parse("foo123_bar", {:field, ["foo123_bar"]})
    assert_parse("_baz", {:field, ["_baz"]})
    assert_parse_error("123foo")
  end

  test "function" do
    assert_parse("f()", {:fun, ["f"]})
    assert_parse("f(x)", {:fun, ["f", {:field, ["x"]}]})
    assert_parse("f( x )", {:fun, ["f", {:field, ["x"]}]})
    assert_parse("f (x)", {:fun, ["f", {:field, ["x"]}]})
    assert_parse("f(x)", {:fun, ["f", {:field, ["x"]}]})
    assert_parse("f(g(x))", {:fun, ["f", {:fun, ["g", {:field, ["x"]}]}]})
    assert_parse("f(x,y)", {:fun, ["f", {:field, ["x"]}, {:field, ["y"]}]})
    assert_parse("f(x, y)", {:fun, ["f", {:field, ["x"]}, {:field, ["y"]}]})
    assert_parse("f(g(x), y)", {:fun, ["f", {:fun, ["g", {:field, ["x"]}]}, {:field, ["y"]}]})
    assert_parse_error("f(")
    assert_parse_error("f(x,)")
    assert_parse_error("f(x,,)")
    assert_parse_error("f(x, ,y)")
    assert_parse_error("123(x)")
    assert_parse_error("f(g(x)")
  end

  test "invalid syntax" do
    assert_parse_error("1 2 f)x((")
  end
end

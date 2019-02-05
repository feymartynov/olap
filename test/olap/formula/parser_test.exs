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

  test "number" do
    assert_parse("123", {:number, [123.0]})
    assert_parse("123.45", {:number, [123.45]})
    assert_parse_error("123..45")
    assert_parse_error("123.45.67")
    assert_parse_error(".")
    assert_parse_error(".0")
    assert_parse_error("123. 45")
    assert_parse_error("1 23")
  end

  test "identifier" do
    assert_parse("foo", {:identifier, ["foo"]})
    assert_parse("foo_bar", {:identifier, ["foo_bar"]})
    assert_parse("foo123", {:identifier, ["foo123"]})
    assert_parse("foo123_bar", {:identifier, ["foo123_bar"]})
    assert_parse("_baz", {:identifier, ["_baz"]})
    assert_parse_error("123foo")
  end

  test "function" do
    assert_parse("f()", {:function_call, [{:identifier, ["f"]}]})
    assert_parse("f(x)", {:function_call, [{:identifier, ["f"]}, {:identifier, ["x"]}]})
    assert_parse("f( x )", {:function_call, [{:identifier, ["f"]}, {:identifier, ["x"]}]})
    assert_parse("f (x)", {:function_call, [{:identifier, ["f"]}, {:identifier, ["x"]}]})
    assert_parse("f(x)", {:function_call, [{:identifier, ["f"]}, {:identifier, ["x"]}]})

    assert_parse(
      "f(g(x))",
      {:function_call,
       [{:identifier, ["f"]}, {:function_call, [{:identifier, ["g"]}, {:identifier, ["x"]}]}]}
    )

    assert_parse(
      "f(x,y)",
      {:function_call, [{:identifier, ["f"]}, {:identifier, ["x"]}, {:identifier, ["y"]}]}
    )

    assert_parse(
      "f(x, y)",
      {:function_call, [{:identifier, ["f"]}, {:identifier, ["x"]}, {:identifier, ["y"]}]}
    )

    assert_parse(
      "f(g(x), y)",
      {:function_call,
       [
         {:identifier, ["f"]},
         {:function_call, [{:identifier, ["g"]}, {:identifier, ["x"]}]},
         {:identifier, ["y"]}
       ]}
    )

    assert_parse_error("f(")
    assert_parse_error("f(x,)")
    assert_parse_error("f(x,,)")
    assert_parse_error("f(x, ,y)")
    assert_parse_error("f(g(x)")
  end

  test "operators with precedence and parentheses" do
    assert_parse("-1", {:unary_prefix_operator, [?-, {:number, [1.0]}]})
    assert_parse("-(1)", {:unary_prefix_operator, [?-, {:number, [1.0]}]})
    assert_parse("(((1)))", {:number, [1.0]})
    assert_parse("1 + 2", {:binary_operator, [{:number, [1.0]}, ?+, {:number, [2.0]}]})
    assert_parse("1 * 2", {:binary_operator, [{:number, [1.0]}, ?*, {:number, [2.0]}]})
    assert_parse("(1)", {:number, [1.0]})

    assert_parse(
      "(1 + 2) * 3",
      {:binary_operator,
       [{:binary_operator, [{:number, [1.0]}, ?+, {:number, [2.0]}]}, ?*, {:number, [3.0]}]}
    )

    assert_parse(
      "(1 + 2) * -(3 + 4)",
      {:binary_operator,
       [
         {:binary_operator, [{:number, [1.0]}, ?+, {:number, [2.0]}]},
         ?*,
         {:unary_prefix_operator,
          [?-, {:binary_operator, [{:number, [3.0]}, ?+, {:number, [4.0]}]}]}
       ]}
    )

    assert_parse(
      "-f(x)",
      {:unary_prefix_operator,
       [?-, {:function_call, [{:identifier, ["f"]}, {:identifier, ["x"]}]}]}
    )

    assert_parse(
      "f(x) / g(y)",
      {:binary_operator,
       [
         {:function_call, [{:identifier, ["f"]}, {:identifier, ["x"]}]},
         ?/,
         {:function_call, [{:identifier, ["g"]}, {:identifier, ["y"]}]}
       ]}
    )

    assert_parse(
      "(1 + (2 - 4)) * 3",
      {:binary_operator,
       [
         {:binary_operator,
          [{:number, [1.0]}, ?+, {:binary_operator, [{:number, [2.0]}, ?-, {:number, [4.0]}]}]},
         ?*,
         {:number, [3.0]}
       ]}
    )

    assert_parse(
      "2 ^ 3 * 4 + 1",
      {:binary_operator,
       [
         {:binary_operator,
          [{:binary_operator, [{:number, [2.0]}, ?^, {:number, [3.0]}]}, ?*, {:number, [4.0]}]},
         ?+,
         {:number, [1.0]}
       ]}
    )

    assert_parse("2 > 1", {:binary_operator, [{:number, [2.0]}, ?>, {:number, [1.0]}]})
    assert_parse("2 >= 1", {:binary_operator, [{:number, [2.0]}, ">=", {:number, [1.0]}]})
    assert_parse("1 < 2", {:binary_operator, [{:number, [1.0]}, ?<, {:number, [2.0]}]})
    assert_parse("1 <= 2", {:binary_operator, [{:number, [1.0]}, "<=", {:number, [2.0]}]})
    assert_parse("1 = 1", {:binary_operator, [{:number, [1.0]}, ?=, {:number, [1.0]}]})
    assert_parse("1 <> 2", {:binary_operator, [{:number, [1.0]}, "<>", {:number, [2.0]}]})
  end

  test "invalid syntax" do
    assert_parse_error("1 2 f)x((")
  end
end

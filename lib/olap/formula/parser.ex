defmodule Olap.Formula.Parser do
  import NimbleParsec

  # Numbers: parse all as floats
  defcombinatorp(
    :number,
    integer(min: 1)
    |> optional(ignore(ascii_char([?.])) |> integer(min: 1))
    |> reduce({:parse_float, []})
    |> tag(:number)
  )

  defp parse_float(components) do
    case components |> Enum.join(".") |> Float.parse() do
      {number, ""} -> number
      _ -> raise "Float parse error"
    end
  end

  # Identifiers
  defcombinatorp(
    :identifier,
    ascii_string([?a..?z, ?_], min: 1)
    |> optional(ascii_string([?a..?z, ?_, ?0..?9], min: 1))
    |> reduce({Enum, :join, []})
    |> tag(:identifier)
  )

  # Skip whitespaces, CR & LF characters
  defcombinatorp(:spaces, ignore(optional(ascii_string([32, 10, 13], min: 1))))

  # Function arguments
  defcombinatorp(:args, parsec(:expr) |> optional(parsec(:additional_args)))

  # Comma separation of function arguments
  defcombinatorp(
    :additional_args,
    ignore(ascii_char([?,]))
    |> parsec(:spaces)
    |> parsec(:expr)
    |> parsec(:spaces)
    |> optional(parsec(:additional_args))
  )

  # Function calls: f(x), f(x, y), f(g(x), y) and so on
  defcombinatorp(
    :function_call,
    parsec(:identifier)
    |> parsec(:spaces)
    |> ignore(ascii_char([?(]))
    |> parsec(:spaces)
    |> optional(parsec(:args))
    |> parsec(:spaces)
    |> ignore(ascii_char([?)]))
    |> tag(:function_call)
  )

  # Unary operators: -
  defcombinatorp(
    :unary_prefix_operator,
    ascii_char([?-])
    |> parsec(:spaces)
    |> parsec(:expr)
    |> tag(:unary_prefix_operator)
  )

  # Terms that can be operands to binary operators
  defcombinatorp(
    :term,
    choice([
      parsec(:function_call),
      parsec(:unary_prefix_operator),
      parsec(:number),
      parsec(:identifier)
    ])
  )

  # Parentheses scoping
  defcombinatorp(
    :scoped_term,
    choice([
      ignore(ascii_char([?(]))
      |> concat(parsec(:expr))
      |> ignore(ascii_char([?)])),
      parsec(:term)
    ])
  )

  # First precedence binary operators: ^
  defcombinatorp(
    :prec1,
    choice([
      parsec(:scoped_term)
      |> parsec(:spaces)
      |> ascii_char([?^])
      |> parsec(:spaces)
      |> parsec(:prec1)
      |> tag(:binary_operator),
      parsec(:scoped_term)
    ])
  )

  # Second precedence binary operators: *, /
  defcombinatorp(
    :prec2,
    choice([
      parsec(:prec1)
      |> parsec(:spaces)
      |> ascii_char([?*, ?/])
      |> parsec(:spaces)
      |> parsec(:prec2)
      |> tag(:binary_operator),
      parsec(:prec1)
    ])
  )

  # Third precedence binary operators: +, -
  defcombinatorp(
    :prec3,
    choice([
      parsec(:prec2)
      |> parsec(:spaces)
      |> ascii_char([?+, ?-])
      |> parsec(:spaces)
      |> parsec(:prec3)
      |> tag(:binary_operator),
      parsec(:prec2)
    ])
  )

  # Fourth precedence binary operators: >, >=, <, <=, =, <>
  defcombinatorp(
    :prec4,
    choice([
      parsec(:prec3)
      |> parsec(:spaces)
      |> choice([
        string(">="),
        string("<="),
        string("<>"),
        ascii_char([?>, ?<, ?=])
      ])
      |> parsec(:spaces)
      |> parsec(:prec4)
      |> tag(:binary_operator),
      parsec(:prec3)
    ])
  )

  # Endpoint
  defparsecp(:expr, parsec(:prec4))

  def parse(input) do
    case expr(input) do
      {:ok, [acc], "", _, _, _} -> {:ok, acc}
      {:ok, _, rest, _, _, _} -> {:error, "could not parse " <> rest}
      {:error, reason, _rest, _, _, _} -> {:error, reason}
    end
  end
end

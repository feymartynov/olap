defmodule Olap.Formula.Parser do
  import NimbleParsec

  defcombinatorp(
    :term,
    ascii_string([?a..?z, ?_], min: 1)
    |> optional(ascii_string([?a..?z, ?_, ?0..?9], min: 1))
    |> reduce({Enum, :join, []})
  )

  defcombinatorp(:field, parsec(:term) |> tag(:field))
  defcombinatorp(:spaces, ignore(optional(ascii_string([32, 10, 13], min: 1))))

  defcombinatorp(
    :args,
    parsec(:expr)
    |> optional(parsec(:additional_args))
  )

  defcombinatorp(
    :additional_args,
    ignore(ascii_char([?,]))
    |> parsec(:spaces)
    |> parsec(:expr)
    |> parsec(:spaces)
    |> optional(parsec(:additional_args))
  )

  defcombinatorp(
    :fun,
    parsec(:term)
    |> parsec(:spaces)
    |> ignore(ascii_char([?(]))
    |> parsec(:spaces)
    |> optional(parsec(:args))
    |> parsec(:spaces)
    |> ignore(ascii_char([?)]))
    |> tag(:fun)
  )

  defparsecp(:expr, choice([parsec(:fun), parsec(:field)]))

  def parse(input) do
    case expr(input) do
      {:ok, [acc], "", _, _, _} -> {:ok, acc}
      {:ok, _, rest, _, _, _} -> {:error, "could not parse " <> rest}
      {:error, reason, _rest, _, _, _} -> {:error, reason}
    end
  end
end

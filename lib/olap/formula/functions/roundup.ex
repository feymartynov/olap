defmodule Olap.Formula.Functions.Roundup do
  @behaviour Olap.Formula.Function

  def call([value]), do: {:ok, ceil(value)}
  def call([]), do: {:error, "Expected exactly one argument"}
end

defmodule Olap.Formula.Functions.Round do
  @behaviour Olap.Formula.Function

  def call([value]), do: {:ok, round(value)}
  def call([]), do: {:error, "Expected exactly one argument"}
end

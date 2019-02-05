defmodule Olap.Formula.Functions.Rounddown do
  @behaviour Olap.Formula.Function

  def call([value]), do: {:ok, floor(value)}
  def call([]), do: {:error, "Expected exactly one argument"}
end

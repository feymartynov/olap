defmodule Olap.Formula.Functions.Average do
  @behaviour Olap.Formula.Function

  def call([]), do: {:error, "Expected at least one argument"}
  def call(values), do: {:ok, Enum.sum(values) / Enum.count(values)}
end

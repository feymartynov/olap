defmodule Olap.Formula.Functions.Min do
  @behaviour Olap.Formula.Function

  def call([]), do: {:error, "Expected at least one argument"}
  def call(values), do: {:ok, Enum.min(values)}
end

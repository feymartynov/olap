defmodule Olap.Formula.Functions.Max do
  @behaviour Olap.Formula.Function

  def call([]), do: {:error, "Expected at least one argument"}
  def call(values), do: {:ok, Enum.max(values)}
end

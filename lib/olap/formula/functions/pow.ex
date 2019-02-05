defmodule Olap.Formula.Functions.Pow do
  @behaviour Olap.Formula.Function

  def call(values) when length(values) < 2, do: {:error, "Expected at least 2 arguments"}
  def call([a, b]), do: {:ok, :math.pow(a, b)}
  def call(values) when is_list(values), do: {:ok, Enum.reduce(values, &:math.pow(&2, &1))}
end

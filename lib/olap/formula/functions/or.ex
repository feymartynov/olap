defmodule Olap.Formula.Functions.Or do
  @behaviour Olap.Formula.Function

  def call(values) when length(values) < 2, do: {:error, "Expected at least 2 arguments"}
  def call([a, b]), do: {:ok, a || b}
  def call(values) when is_list(values), do: {:ok, Enum.reduce(values, &(&2 || &1))}
end

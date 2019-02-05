defmodule Olap.Formula.Functions.Eq do
  @behaviour Olap.Formula.Function

  def call([a, b]), do: {:ok, a == b}
  def call(_), do: {:error, "Expected exactly 2 arguments"}
end

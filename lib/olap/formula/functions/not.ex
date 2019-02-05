defmodule Olap.Formula.Functions.Not do
  @behaviour Olap.Formula.Function

  def call([x]), do: {:ok, !x}
  def call(_), do: {:error, "Expected exactly one argument"}
end

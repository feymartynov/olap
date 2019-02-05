defmodule Olap.Formula.Functions.Count do
  @behaviour Olap.Formula.Function

  def call(values), do: {:ok, Enum.count(values)}
end

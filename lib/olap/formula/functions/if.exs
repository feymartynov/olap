defmodule Olap.Formula.Functions.If do
  @behaviour Olap.Formula.Function

  def call([con, then_expr, _]) when con != false && con != 0, do: {:ok, then_expr}
  def call([_, _, else_expr]), do: {:ok, else_expr}
  def call(_), do: {:error, "Expected exactly 3 arguments"}
end

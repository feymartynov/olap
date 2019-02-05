defmodule Olap.Formula.Functions.Mod do
  @behaviour Olap.Formula.Function

  def call(values) when length(values) < 2, do: {:error, "Expected at least 2 arguments"}
  def call([_, 0]), do: {:error, "Division by zero"}
  def call([_, 0.0]), do: {:error, "Division by zero"}
  def call([a, b]), do: {:ok, rem(trunc(a), trunc(b))}

  def call([_ | tail] = values) when is_list(values) do
    if Enum.any?(tail, &(&1 == 0)) do
      {:error, "Division by zero"}
    else
      {:ok, Enum.reduce(values, &rem(trunc(&2), trunc(&1)))}
    end
  end
end

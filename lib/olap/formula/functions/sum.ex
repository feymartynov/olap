defmodule Olap.Formula.Functions.Sum do
  def sum_int([values]), do: Enum.sum(values)
  def sum_money([values]), do: Enum.reduce(values, &Money.add(&2, &1))
end

defmodule Olap.Formula.Functions.Sum do
  @behaviour Olap.Formula.Function

  alias Olap.Types

  def signatures do
    %{
      {[Types.Integer], Types.Integer} => &sum_int/1,
      {[Types.Money], Types.Money} => &sum_money/1
    }
  end

  def sum_int([items]), do: Enum.sum(items)
  def sum_money([items]), do: Enum.reduce(items, &Money.add(&2, &1))
end

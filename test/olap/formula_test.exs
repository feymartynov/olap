defmodule Olap.FormulaTest do
  use ExUnit.Case, async: true
  alias Olap.{Cube, Formula}

  test "evaluate formula" do
    field_set = Cube.get("sales").field_set
    assert {:ok, formula} = Formula.build("sum(total_amount)", field_set)

    items = [100, 200] |> Enum.map(&%{"total_amount" => Money.new(&1, :RUB)})
    assert formula |> Formula.evaluate(items) == {:ok, Money.new(300, :RUB)}
  end

  test "fail to build formula with bad signature" do
    field_set = Cube.get("sales").field_set
    assert {:error, _} = Formula.build("sum(customer)", field_set)
  end
end

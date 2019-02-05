defmodule Olap.FormulaTest do
  use ExUnit.Case, async: true
  alias Olap.Formula

  test "evaluate formula" do
    assert {:ok, formula} = Formula.build("mod(2 ^ 3 * 4, 5) * round(7 / -3) + 0.5")
    assert formula |> Formula.evaluate() == {:ok, -3.5}
  end
end

defmodule Olap.PivotTableTest do
  use ExUnit.Case
  alias Olap.{Cube, PivotTable}

  # +--------+-----------------------+-----------------------+
  # |        |          2018         |          2019         |
  # |        +-----+-----+-----+-----+-----+-----+-----+-----+
  # |        | Q1  | Q2  | Q3  | Q4  | Q1  | Q2  | Q3  | Q4  |
  # +--------+-----+-----+-----+-----+-----+-----+-----+-----+
  # | profit | 100 | 200 | 300 | 400 | 500 |  -  |  -  |  -  |
  # +--------+-----+-----+-----+-----+-----+-----+-----+-----+
  # | loss   |  10 |  20 |  30 |  40 |  50 |  -  |  -  |  -  |
  # +--------+-----+-----+-----+-----+-----+-----+-----+-----+
  #
  # 2018: 100 + 200 + 300 + 400 - 10 - 20 - 30 - 40 = 900
  # 2019: 500 - 50 = 450

  @data [
    {~w(2018Q1 profit), 100},
    {~w(2018Q2 profit), 200},
    {~w(2018Q3 profit), 300},
    {~w(2018Q4 profit), 400},
    {~w(2019Q1 profit), 500},
    {~w(2018Q1 loss), 10},
    {~w(2018Q2 loss), 20},
    {~w(2018Q3 loss), 30},
    {~w(2018Q4 loss), 40},
    {~w(2019Q1 loss), 50}
  ]

  test "calculate pivot table" do
    {:ok, cube} = Olap.get(:cubes, "pnl_over_time")

    for {address, value} <- @data do
      :ok = cube |> Cube.put(address, value)
    end

    pivot_table = PivotTable.build("tbl", cube, [{"time", ~w(2018 2019)}, {"pnl", ~w(all)}])
    assert PivotTable.calculate(pivot_table) == [[900], [450]]
  end
end

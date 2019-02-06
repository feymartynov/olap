defmodule Olap.CubeTest do
  use Olap.DataCase
  alias Olap.{Cube, Hierarchy}

  test "consolidated values cache" do
    {:ok, cube} = :cubes |> Olap.get("pnl_over_time")
    address = cube.dimensions |> Enum.map(&Hierarchy.get_root(&1))

    # no caching without consolidation demand
    :ok = cube |> Cube.put(~w(2018Q1 profit), 100)
    assert cube |> Cube.get_cached_consolidated_value(address) == :error

    # cache on the first demand
    assert cube |> Cube.consolidate(address) == 100
    assert cube |> Cube.get_cached_consolidated_value(address) == {:ok, 100}

    # invalidate cache on value change
    :ok = cube |> Cube.put(~w(2018Q1 profit), 200)
    assert cube |> Cube.get_cached_consolidated_value(address) == :error

    # recalculate cache on the next demand
    assert cube |> Cube.consolidate(address) == 200
    assert cube |> Cube.get_cached_consolidated_value(address) == {:ok, 200}
  end
end

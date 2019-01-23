defmodule Olap.Cube.Aggregator.AddressCombinatorTest do
  use ExUnit.Case, async: true
  alias Olap.Cube.Aggregator.AddressCombinator

  @tree1 %{1 => %{2 => %{3 => nil, 4 => nil}, 5 => nil}}
  @tree2 %{a: %{b: %{c: nil}, d: nil}}
  @trees_set %AddressCombinator.CoordinateTreesSet{trees: [@tree1, @tree2]}

  @expectation [
    [[1, 2, 3], [:a, :b, :c]],
    [[2, 3], [:a, :b, :c]],
    [[3], [:a, :b, :c]],
    [[1, 2, 4], [:a, :b, :c]],
    [[2, 4], [:a, :b, :c]],
    [[4], [:a, :b, :c]],
    [[1, 5], [:a, :b, :c]],
    [[5], [:a, :b, :c]],
    [[1, 2, 3], [:b, :c]],
    [[2, 3], [:b, :c]],
    [[3], [:b, :c]],
    [[1, 2, 4], [:b, :c]],
    [[2, 4], [:b, :c]],
    [[4], [:b, :c]],
    [[1, 5], [:b, :c]],
    [[5], [:b, :c]],
    [[1, 2, 3], [:c]],
    [[2, 3], [:c]],
    [[3], [:c]],
    [[1, 2, 4], [:c]],
    [[2, 4], [:c]],
    [[4], [:c]],
    [[1, 5], [:c]],
    [[5], [:c]],
    [[1, 2, 3], [:a, :d]],
    [[2, 3], [:a, :d]],
    [[3], [:a, :d]],
    [[1, 2, 4], [:a, :d]],
    [[2, 4], [:a, :d]],
    [[4], [:a, :d]],
    [[1, 5], [:a, :d]],
    [[5], [:a, :d]],
    [[1, 2, 3], [:d]],
    [[2, 3], [:d]],
    [[3], [:d]],
    [[1, 2, 4], [:d]],
    [[2, 4], [:d]],
    [[4], [:d]],
    [[1, 5], [:d]],
    [[5], [:d]]
  ]

  test "combinate addresses by trees" do
    assert @trees_set |> AddressCombinator.iterator() |> Enum.to_list() == @expectation
  end
end

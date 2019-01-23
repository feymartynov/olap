defmodule Olap.Cube.Aggregator.AddressCombinator do
  defmodule CoordinateTreesSet do
    defstruct trees: []

    def new(dimensions) do
      %__MODULE__{trees: Enum.map(dimensions, fn _ -> %{} end)}
    end

    def put_address(%__MODULE__{} = trees_set, address) do
      Map.update!(trees_set, :trees, fn trees ->
        for {tree, coordinate} <- Stream.zip(trees, address) do
          path = coordinate |> Enum.reverse() |> Enum.map(&Access.key(&1, %{}))
          tree |> put_in(path, nil)
        end
      end)
    end
  end

  def iterator(%CoordinateTreesSet{trees: trees}) do
    trees
    |> Enum.map(fn tree -> tree |> iterate() |> Stream.flat_map(&zoom_out/1) end)
    |> combinate()
  end

  defp iterate(tree) do
    Stream.flat_map(tree, fn
      {key, nil} -> [[key]]
      {key, subtree} -> subtree |> iterate() |> Stream.map(&[key | &1])
    end)
  end

  defp zoom_out([]), do: []
  defp zoom_out([_ | tail] = x), do: [x | zoom_out(tail)]

  defp combinate([x]), do: Stream.map(x, &[&1])

  defp combinate([head | tail]) do
    Stream.flat_map(combinate(tail), fn address ->
      Stream.map(head, &[&1 | address])
    end)
  end
end

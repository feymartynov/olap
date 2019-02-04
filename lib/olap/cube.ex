defmodule Olap.Cube do
  defstruct name: nil, dimensions: [], table: nil

  def build(%{"name" => name, "dimensions" => dimension_names}) do
    cube_dimensions =
      for dimension_name <- dimension_names do
        {:ok, dimension} = Olap.get(:dimensions, dimension_name)
        dimension
      end

    table = :ets.new(:cube, [:public])
    %__MODULE__{name: name, dimensions: cube_dimensions, table: table}
  end

  def put(%__MODULE__{table: table} = cube, address, value) when is_list(address) do
    with {:ok, address} <- cube |> cast_address(address) do
      :ets.insert(table, {address, value})
      :ok
    end
  end

  defp cast_address(%__MODULE__{dimensions: dims}, addr) when length(dims) != length(addr) do
    {:error, "Address must have exactly #{length(dims)} components, got #{length(addr)}"}
  end

  defp cast_address(%__MODULE__{dimensions: dimensions}, address) do
    address
    |> Stream.zip(dimensions)
    |> Enum.reduce_while({:ok, []}, fn {aliaz, dimension}, {:ok, acc} ->
      case Map.fetch(dimension.leafs, aliaz) do
        {:ok, ref} -> {:cont, {:ok, [ref | acc]}}
        :error -> {:halt, {:error, "No leaf `#{aliaz}` in dimension `#{dimension.name}`"}}
      end
    end)
    |> case do
      {:ok, refs} -> {:ok, Enum.reverse(refs)}
      other -> other
    end
  end

  def consolidate(%__MODULE__{dimensions: dims} = cube, addr) when length(addr) == length(dims) do
    case Enum.find_index(addr, &(&1.nodes != [])) do
      nil -> Enum.reduce(addr, get_leaf(cube, Enum.map(addr, & &1.ref)) || 0, &(&2 * &1.weight))
      index -> cube |> consolidate_children(addr, index) |> Enum.sum()
    end
  end

  defp consolidate_children(cube, address, index) do
    for child_node <- Enum.at(address, index).nodes do
      child_address =
        Enum.map(Stream.with_index(address), fn
          {_, ^index} -> child_node
          {node, _} -> node
        end)

      cube |> consolidate(child_address)
    end
  end

  defp get_leaf(%__MODULE__{table: table}, ref_address) do
    case :ets.lookup(table, ref_address) do
      [{^ref_address, value}] -> value
      [] -> nil
    end
  end
end

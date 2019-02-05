defmodule Olap.Cube do
  alias Olap.Hierarchy

  defstruct name: nil, dimensions: [], table: nil, consolidation_cache_table: nil

  def build(%{"name" => name, "dimensions" => hierarchy_names}) do
    dimensions =
      for hierarchy_name <- hierarchy_names do
        {:ok, hierarchy} = Olap.get(:hierarchies, hierarchy_name)
        hierarchy
      end

    %__MODULE__{
      name: name,
      dimensions: dimensions,
      table: :ets.new(:cube, [:public]),
      consolidation_cache_table: :ets.new(:cube_consolidation_cache, [:public])
    }
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
    |> Enum.reduce_while({:ok, []}, fn {as, dimension}, {:ok, acc} ->
      with {:ok, node} <- Hierarchy.find_node(dimension, as),
           true <- Hierarchy.leaf?(dimension, node) || {:error, "`#{as}` is not a leaf node"} do
        {:cont, {:ok, [node.ref | acc]}}
      else
        other -> {:halt, other}
      end
    end)
    |> case do
      {:ok, refs} -> {:ok, Enum.reverse(refs)}
      other -> other
    end
  end

  def consolidate(%__MODULE__{dimensions: dims} = cube, addr) when length(addr) == length(dims) do
    addr
    |> Enum.zip(dims)
    |> Enum.find_index(fn {node, hierarchy} -> !Hierarchy.leaf?(hierarchy, node) end)
    |> case do
      nil -> Enum.reduce(addr, get_leaf(cube, Enum.map(addr, & &1.ref)) || 0, &(&2 * &1.weight))
      index -> cube |> consolidate_children(addr, index) |> Enum.sum()
    end
  end

  defp consolidate_children(cube, address, index) do
    hierarchy = cube.dimensions |> Enum.at(index)
    node = address |> Enum.at(index)

    for child_node <- hierarchy |> Hierarchy.get_children(node) do
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

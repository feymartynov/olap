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
      :ets.insert(table, {address_to_key(address), value})
      invalidate_consolidation_cache(cube, address)
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
      case Hierarchy.find_node(dimension, as) do
        {:ok, node} -> {:cont, {:ok, [node | acc]}}
        other -> {:halt, other}
      end
    end)
    |> case do
      {:ok, refs} -> {:ok, Enum.reverse(refs)}
      other -> other
    end
  end

  defp address_to_key(address), do: Enum.map(address, & &1.ref)

  defp invalidate_consolidation_cache(%__MODULE__{} = cube, address) do
    address
    |> Enum.zip(cube.dimensions)
    |> combinate()
    |> Stream.each(&:ets.delete(cube.consolidation_cache_table, address_to_key(&1)))
    |> Stream.run()
  end

  defp combinate([head]) do
    head |> iterate() |> Stream.map(&[&1])
  end

  defp combinate([head | tail]) do
    head |> iterate() |> Stream.flat_map(fn x -> tail |> combinate() |> Stream.map(&[x | &1]) end)
  end

  defp iterate({node, dimension}) do
    Stream.unfold(node, fn
      nil -> nil
      x -> {x, Hierarchy.get_parent(dimension, x)}
    end)
  end

  def consolidate(%__MODULE__{dimensions: dims} = cube, addr) when length(addr) == length(dims) do
    case get_cached_consolidated_value(cube, addr) do
      {:ok, value} ->
        value

      :error ->
        value = cube |> do_consolidate(addr)
        cube |> cache_consolidated_value(addr, value)
        value
    end
  end

  def get_cached_consolidated_value(%__MODULE__{consolidation_cache_table: table}, address) do
    address = Enum.map(address, & &1.ref)

    case :ets.lookup(table, address) do
      [{^address, value}] -> {:ok, value}
      [] -> :error
    end
  end

  defp cache_consolidated_value(%__MODULE__{consolidation_cache_table: table}, address, value) do
    :ets.insert(table, {address_to_key(address), value})
  end

  defp do_consolidate(%__MODULE__{dimensions: dimensions} = cube, addr) do
    addr
    |> Enum.zip(dimensions)
    |> Enum.find_index(fn {node, hierarchy} -> !Hierarchy.leaf?(hierarchy, node) end)
    |> case do
      nil -> Enum.reduce(addr, get_leaf(cube, addr) || 0, &(&2 * &1.weight))
      index -> cube |> consolidate_children(addr, index) |> Enum.sum()
    end
  end

  defp consolidate_children(cube, address, index) do
    hierarchy = cube.dimensions |> Enum.at(index)
    node = address |> Enum.at(index)
    children = hierarchy |> Hierarchy.get_children(node)

    consolidate_child = fn child_node ->
      child_address =
        Enum.map(Stream.with_index(address), fn
          {_, ^index} -> child_node
          {node, _} -> node
        end)

      cube |> consolidate(child_address)
    end

    Olap.TaskSupervisor
    |> Task.Supervisor.async_stream(children, consolidate_child, timeout: 3_600_000)
    |> Enum.map(fn {:ok, result} -> result end)
  end

  defp get_leaf(%__MODULE__{table: table}, address) do
    key = address_to_key(address)

    case :ets.lookup(table, key) do
      [{^key, value}] -> value
      [] -> nil
    end
  end
end

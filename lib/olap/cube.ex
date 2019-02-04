defmodule Olap.Cube do
  defmodule Aggregation do
    defstruct name: nil, formula: nil
  end

  alias Olap.{FieldSet, Formula}
  alias __MODULE__.{Aggregator, Dimension}
  alias __MODULE__.Aggregator.AddressCombinator.CoordinateTreesSet

  @aggregation_timeout 60 * 60 * 1000

  defstruct name: nil,
            field_set: nil,
            dimensions: [],
            table: nil,
            leafs_table: nil,
            aggregations: [],
            aggregations_table: nil

  def init(specs) do
    :ets.new(:cubes, [:named_table, :public, read_concurrency: true])

    Enum.reduce_while(specs, :ok, fn spec, _ ->
      with {:ok, cube} <- build(spec),
           :ok <- register(cube) do
        {:cont, :ok}
      else
        other -> {:halt, other}
      end
    end)
  end

  def build(%{
        "name" => name,
        "fields" => fields_spec,
        "dimensions" => dimensions_spec,
        "aggregations" => aggregations_spec
      }) do
    with {:ok, field_set} <- FieldSet.build(fields_spec),
         {:ok, dimensions} <- build_dimensions(dimensions_spec, field_set),
         {:ok, aggregations} <- build_aggregations(aggregations_spec, field_set) do
      {:ok,
       %__MODULE__{
         name: name,
         field_set: field_set,
         dimensions: Enum.reverse(dimensions),
         table: :ets.new(:cube, [:public, read_concurrency: true]),
         leafs_table: :ets.new(:cube, [:public, read_concurrency: true]),
         aggregations: Enum.reverse(aggregations),
         aggregations_table: :ets.new(:cube, [:public, read_concurrency: true])
       }}
    end
  end

  defp build_dimensions(specs, field_set) do
    Enum.reduce_while(specs, {:ok, []}, fn spec, {:ok, acc} ->
      case Dimension.build(spec, field_set) do
        {:ok, dimension} -> {:cont, {:ok, [dimension | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp build_aggregations(specs, field_set) do
    Enum.reduce_while(specs, {:ok, []}, fn spec, {:ok, acc} ->
      with {:ok, formula} <- Formula.build(spec["formula"], field_set),
           :ok <- validate_aggregation_formula(formula) do
        aggregation = %Aggregation{name: spec["name"], formula: formula}
        {:cont, {:ok, [aggregation | acc]}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_aggregation_formula(%Formula{variables: variables, return_type: return_type}) do
    if Enum.map(variables, & &1.type) == [return_type] do
      :ok
    else
      {:error,
       "Aggregation formula must have exactly one variable argument of its return type. " <>
         "Got #{inspect(variables)} -> #{inspect(return_type)}"}
    end
  end

  defp register(%__MODULE__{name: name} = cube) do
    case :ets.insert_new(:cubes, {name, cube}) do
      true -> :ok
      false -> {:error, "Duplicate cube name #{name}"}
    end
  end

  def get_address(%__MODULE__{dimensions: dimensions}, item) do
    build_address(dimensions, item)
  end

  def get(name) do
    case :ets.lookup(:cubes, name) do
      [{^name, cube}] -> cube
      [] -> nil
    end
  end

  def put(%__MODULE__{table: table, leafs_table: leafs_table} = cube, items) do
    with {:ok, addressed_items, coordinate_trees_set} <- cube |> address_items(items) do
      for {address, item} <- addressed_items do
        :ets.insert(table, {item["id"], item})
        :ets.insert(leafs_table, {address, item["id"]})
      end

      fun = fn -> cube |> Aggregator.aggregate(coordinate_trees_set) end
      task = Task.Supervisor.async_nolink(Olap.TaskSupervisor, fun, timeout: @aggregation_timeout)
      {:ok, task}
    end
  end

  defp address_items(%__MODULE__{field_set: field_set, dimensions: dimensions}, items) do
    initial_trees = dimensions |> Enum.count() |> CoordinateTreesSet.new()

    Enum.reduce_while(items, {:ok, [], initial_trees}, fn item, {:ok, acc, trees} ->
      with :ok <- field_set |> FieldSet.validate(item),
           {:ok, address} <- dimensions |> build_address(item) do
        {:cont, {:ok, [{address, item} | acc], CoordinateTreesSet.put_address(trees, address)}}
      else
        other -> {:halt, other}
      end
    end)
  end

  defp build_address(dimensions, item) do
    dimensions
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, []}, fn dimension, {:ok, acc} ->
      case dimension |> Dimension.get_coordinate(item[dimension.field.name]) do
        {:ok, coordinate} -> {:cont, {:ok, [coordinate | acc]}}
        other -> {:halt, other}
      end
    end)
  end

  def fetch(%__MODULE__{table: table}, id) when is_integer(id) do
    case :ets.lookup(table, id) do
      [{^id, item}] -> {:ok, item}
      [] -> :error
    end
  end

  def fetch!(%__MODULE__{} = cube, id) when is_integer(id) do
    case fetch(cube, id) do
      {:ok, item} -> item
      :error -> raise KeyError, "Id `#{id}` not found in #{inspect(cube)}"
    end
  end

  def fetch_by_address(%__MODULE__{leafs_table: table} = cube, address) when is_list(address) do
    case :ets.lookup(table, address) do
      [{^address, id}] -> fetch(cube, id)
      [] -> :error
    end
  end

  def fetch_by_address!(%__MODULE__{} = cube, address) when is_list(address) do
    case fetch_by_address(cube, address) do
      {:ok, item} -> item
      :error -> raise KeyError, "Address `#{inspect(address)}` not found in #{inspect(cube)}"
    end
  end

  def fetch_all(%__MODULE__{table: table}) do
    :ets.select(table, [{{:_, :"$1"}, [], [:"$1"]}])
  end

  def get(%__MODULE__{aggregations_table: table}, aggregation, address) when is_list(address) do
    case :ets.match_object(table, {aggregation, address, :_}) do
      [{{^aggregation, ^address}, value}] -> {:ok, value}
      [] -> :error
    end
  end

  def get!(%__MODULE__{} = cube, aggregation, address) when is_list(address) do
    case get(cube, aggregation, address) do
      {:ok, value} ->
        value

      :error ->
        raise KeyError,
              "Aggregation `#{aggregation}` for address `#{inspect(address)}` " <>
                "not found in #{inspect(cube)}"
    end
  end

  def get_inner(%__MODULE__{} = cube, %Aggregation{name: aggregation_name}, address) do
    get_inner(cube, aggregation_name, address)
  end

  def get_inner(%__MODULE__{} = cube, aggregation, address) do
    dimension_lengths =
      for %Dimension{hierarchy: hierarchy} <- cube.dimensions do
        hierarchy |> Stream.filter(& &1.include) |> Enum.count()
      end

    address_ms =
      for {coordinate, dimension_length} <- Enum.zip(address, dimension_lengths) do
        if length(coordinate) == dimension_length do
          coordinate
        else
          [:_ | coordinate]
        end
      end

    :ets.select(cube.aggregations_table, [{{{aggregation, address_ms}, :"$1"}, [], [:"$1"]}])
  end
end

defimpl Inspect, for: Olap.Cube do
  import Inspect.Algebra

  def inspect(cube, _) do
    concat(["#Cube<", cube.name, ">"])
  end
end

defimpl Inspect, for: Olap.Cube.Aggregation do
  import Inspect.Algebra

  def inspect(aggregation, _) do
    concat(["#Aggregation<", aggregation.name, ">"])
  end
end

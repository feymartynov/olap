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
      case Formula.build(spec["formula"], field_set) do
        {:ok, formula} ->
          aggregation = %Aggregation{name: spec["name"], formula: formula}
          {:cont, {:ok, [aggregation | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
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

  def put(%__MODULE__{table: table, dimensions: dimensions} = cube, items) do
    with {:ok, items} <- cube |> validate(items) do
      coordinate_trees_set =
        Enum.reduce(items, CoordinateTreesSet.new(dimensions), fn {address, _} = item, acc ->
          :ets.insert(table, item)
          acc |> CoordinateTreesSet.put_address(address)
        end)

      fun = fn -> cube |> Aggregator.aggregate(coordinate_trees_set) end
      Olap.TaskSupervisor |> Task.Supervisor.start_child(fun, timeout: @aggregation_timeout)
      :ok
    end
  end

  defp validate(%__MODULE__{field_set: field_set, dimensions: dimensions}, items) do
    Enum.reduce_while(items, {:ok, []}, fn item, {:ok, acc} ->
      with :ok <- field_set |> FieldSet.validate(item),
           {:ok, address} <- dimensions |> build_address(item) do
        {:cont, {:ok, [{address, item} | acc]}}
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

  def get(%__MODULE__{table: table}, address) do
    case :ets.lookup(table, address) do
      [{^address, item}] -> item
      [] -> nil
    end
  end

  def get_all(%__MODULE__{table: table}, address) do
    address_ms =
      for coordinate <- address do
        coordinate |> Enum.reverse() |> Enum.reduce(:_, &[&1 | &2])
      end

    :ets.select(table, [{{address_ms, :"$1"}, [], [:"$1"]}])
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

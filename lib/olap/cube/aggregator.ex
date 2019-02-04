defmodule Olap.Cube.Aggregator do
  require Logger

  alias Olap.{Cube, Formula}
  alias Olap.Cube.Aggregation
  alias __MODULE__.AddressCombinator

  @formula_timeout 5000

  def aggregate(%Cube{} = cube, %AddressCombinator.CoordinateTreesSet{} = coordiante_trees_set) do
    jobs = cube |> aggregation_jobs(coordiante_trees_set)

    async_stream_opts = [timeout: @formula_timeout, on_timeout: :kill_task, max_concurrency: 1]
    results = jobs |> Task.async_stream(&formula_task/1, async_stream_opts)

    jobs
    |> Stream.zip(results)
    |> Stream.each(fn {{_, agg, addr}, result} -> handle_result(cube, agg, addr, result) end)
    |> Stream.run()
  end

  defp aggregation_jobs(cube, coordiante_trees_set) do
    coordiante_trees_set
    |> AddressCombinator.iterator()
    |> Stream.flat_map(fn address -> Stream.map(cube.aggregations, &{cube, &1, address}) end)
  end

  defp formula_task({cube, %Aggregation{formula: formula} = aggregation, address}) do
    address |> IO.inspect(charlists: :as_lists)

    items =
      case node_type(cube, address) do
        :leaf ->
          :ets.select(cube.leafs_table, [{:"$1", [], [:"$1"]}])
          |> IO.inspect(charlists: :as_lists)

          [cube |> Cube.fetch_by_address!(address)]

        :consolidated ->
          cube
          |> Cube.get_inner(aggregation, address)
          |> Enum.map(&%{List.first(aggregation.formula.variables).name => &1})
      end

    formula
    |> Formula.evaluate(items)
    |> IO.inspect(label: inspect(address, charlists: :as_lists))
  end

  # TODO: suboptimal
  defp node_type(%Cube{dimensions: dimensions}, address) do
    dimension_lengths =
      for dimension <- dimensions do
        dimension.hierarchy |> Stream.filter(& &1.include) |> Enum.count()
      end

    coordinate_lengths = address |> Enum.map(&length(&1))
    if coordinate_lengths == dimension_lengths, do: :leaf, else: :consolidated
  end

  defp handle_result(cube, aggregation, address, {:ok, {:ok, result}}) do
    :ets.insert(cube.aggregations_table, {{aggregation.name, address}, result})
  end

  defp handle_result(cube, aggregation, address, {:ok, other}) do
    log_error(cube, aggregation, address, "formula evaluation failed: #{inspect(other)}")
  end

  defp handle_result(cube, aggregation, address, {:error, reason}) do
    log_error(cube, aggregation, address, reason)
  end

  defp handle_result(cube, aggregation, address, {:exit, :timeout}) do
    log_error(cube, aggregation, address, "timeout after #{@formula_timeout}ms")
  end

  defp log_error(cube, aggregation, address, reason) do
    full_name = "#{cube.name}.#{aggregation.name}"
    Logger.error("Aggregation `#{full_name}` failed on `#{inspect(address)}`: #{inspect(reason)}")
  end
end

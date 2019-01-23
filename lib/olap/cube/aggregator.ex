defmodule Olap.Cube.Aggregator do
  require Logger

  alias Olap.{Cube, Formula}
  alias Olap.Cube.Aggregation
  alias __MODULE__.AddressCombinator

  @formula_timeout 5000

  def aggregate(%Cube{} = cube, %AddressCombinator.CoordinateTreesSet{} = coordiante_trees_set) do
    jobs = cube |> aggregation_jobs(coordiante_trees_set)

    async_stream_opts = [timeout: @formula_timeout, on_timeout: :kill_task]
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

  defp formula_task({cube, %Aggregation{formula: formula}, address}) do
    items = cube |> Cube.get_all(address)
    formula |> Formula.evaluate(items)
  end

  defp handle_result(cube, aggregation, address, {:ok, {:ok, result}}) do
    :ets.insert(cube.aggregations_table, {aggregation.name, address, result})
  end

  defp handle_result(cube, aggregation, address, {:ok, {:error, reason}}) do
    full_name = full_name(cube, aggregation)
    Logger.error("Aggregation `#{full_name}` failed on `#{inspect(address)}`: #{inspect(reason)}")
  end

  defp handle_result(cube, aggregation, address, {:exit, :timeout}) do
    full_name = full_name(cube, aggregation)
    Logger.error("Aggregation `#{full_name}` timed out on `#{inspect(address)}`")
  end

  defp full_name(cube, aggregation), do: "`#{cube.name}.#{aggregation.name}`"
end

defmodule Olap do
  def config do
    :olap |> Application.get_env(:config_path) |> YamlElixir.read_from_file()
  end

  def init do
    with {:ok, config} <- config() do
      init_dimensions(config["dimensions"])
      init_cubes(config["cubes"])
      :ok
    end
  end

  defp init_dimensions(specs) do
    :ets.new(:dimensions, [:named_table, :public, read_concurrency: true])

    for spec <- specs do
      dimension = Olap.Dimension.build(spec)
      :ets.insert_new(:dimensions, {dimension.name, dimension})
    end
  end

  defp init_cubes(specs) do
    :ets.new(:cubes, [:named_table, :public, read_concurrency: true])

    for spec <- specs do
      cube = Olap.Cube.build(spec)
      :ets.insert_new(:cubes, {cube.name, cube})
    end
  end

  def get(table, name) do
    case :ets.lookup(table, name) do
      [{^name, entity}] -> {:ok, entity}
      [] -> :error
    end
  end
end

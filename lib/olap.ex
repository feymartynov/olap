defmodule Olap do
  def config do
    :olap |> Application.get_env(:config_path) |> YamlElixir.read_from_file()
  end

  def init do
    with {:ok, config} <- config() do
      init_hierarchies(config["hierarchies"])
      init_cubes(config["cubes"])
      :ok
    end
  end

  def init_hierarchies(specs) do
    :ets.new(:hierarchies, [:named_table, :public, read_concurrency: true])

    for spec <- specs do
      hierarchy = Olap.Hierarchy.build(spec)
      :ets.insert_new(:hierarchies, {hierarchy.name, hierarchy})
    end
  end

  def init_cubes(specs) do
    :ets.new(:cubes, [:named_table, :public, read_concurrency: true])

    for spec <- specs do
      cube = Olap.Cube.build(spec)
      :ets.insert_new(:cubes, {cube.name, cube})
    end
  end

  def get(table, name) do
    case table |> :ets.whereis() |> :ets.lookup(name) do
      [{^name, entity}] -> {:ok, entity}
      [] -> :error
    end
  end
end

defmodule Olap do
  def config do
    :olap |> Application.get_env(:config_path) |> YamlElixir.read_from_file()
  end

  def init do
    with {:ok, config} <- config() do
      dimensions = build_dimensions(config["dimensions"])
      _cubes = build_cubes(config["cubes"], dimensions)
      :ok
    end
  end

  defp build_dimensions(specs) do
    for spec <- specs, into: %{} do
      dimension = Olap.Dimension.build(spec)
      {dimension.name, dimension}
    end
  end

  defp build_cubes(specs, dimensions) do
    for spec <- specs, into: %{} do
      cube = Olap.Cube.build(spec, dimensions)
      {cube.name, cube}
    end
  end
end

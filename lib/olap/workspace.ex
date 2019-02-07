defmodule Olap.Workspace do
  use Agent

  defstruct config: %{}, cubes: %{}

  def start_link([name, config]) do
    Agent.start_link(fn -> build(config) end, name: name)
  end

  defp build(config) do
    %__MODULE__{
      config: config,
      cubes: build_cubes(config["cubes"], build_hierarchies(config["hierarchies"]))
    }
  end

  defp build_hierarchies(specs) do
    for spec <- specs, into: %{} do
      hierarchy = Olap.Hierarchy.build(spec)
      {hierarchy.name, hierarchy}
    end
  end

  defp build_cubes(specs, hierarchies) do
    for spec <- specs, into: %{} do
      cube = Olap.Cube.build(spec, hierarchies)
      {cube.name, cube}
    end
  end

  def get_config(workspace), do: workspace |> Agent.get(& &1.config)
  def get_cube(workspace, name), do: workspace |> Agent.get(& &1.cubes[name])
end

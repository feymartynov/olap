defmodule Olap.Api.CubeView do
  alias Olap.Cube

  def render(%Cube{} = cube) do
    %{name: cube.name, dimensions: Enum.map(cube.dimensions, & &1.name)}
  end
end

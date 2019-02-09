defmodule Olap.Api.CubeController do
  use Olap.Api.Controller

  alias Olap.{Cube, Workspace}
  alias Olap.Api.CubeView

  def index(conn) do
    cubes = conn.assigns.workspace |> Workspace.get_cubes() |> Map.values()
    conn |> json(200, %{cubes: Enum.map(cubes, &CubeView.render/1)})
  end

  def show(conn) do
    case conn.assigns.workspace |> Workspace.get_cube(conn.params["name"]) do
      %Cube{} = cube -> conn |> json(200, %{cube: CubeView.render(cube)})
      nil -> conn |> json(404, %{error: "Not Found"})
    end
  end
end

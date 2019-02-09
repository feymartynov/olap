defmodule Olap.Api.HierarchyController do
  use Olap.Api.Controller

  alias Olap.{Hierarchy, Workspace}
  alias Olap.Api.HierarchyView

  def index(conn) do
    hierarchies = conn.assigns.workspace |> Workspace.get_hierarchies() |> Map.values()
    conn |> json(200, %{hierarchies: Enum.map(hierarchies, &HierarchyView.render/1)})
  end

  def show(conn) do
    case conn.assigns.workspace |> Workspace.get_hierarchy(conn.params["name"]) do
      %Hierarchy{} = hierarchy -> conn |> json(200, %{hierarchy: HierarchyView.render(hierarchy)})
      nil -> conn |> json(404, %{error: "Not Found"})
    end
  end
end

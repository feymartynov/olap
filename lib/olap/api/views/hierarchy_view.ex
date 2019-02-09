defmodule Olap.Api.HierarchyView do
  alias Olap.Hierarchy

  def render(%Hierarchy{} = hierarchy) do
    %{name: hierarchy.name, nodes: Hierarchy.walk_nodes(hierarchy, &render_nodes/2)}
  end

  defp render_nodes(node, children_results) do
    node
    |> Map.take([:label, :aliases, :weight])
    |> Map.put(:nodes, children_results)
  end
end

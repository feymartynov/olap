defmodule Olap.Hierarchy do
  defmodule Node do
    defstruct ref: nil, label: nil, aliases: [], weight: 1

    def build(spec) do
      %Node{
        ref: make_ref(),
        label: spec["label"],
        aliases: [spec["label"] | Map.get(spec, "aliases", [])],
        weight: spec["weight"] || 1
      }
    end
  end

  defstruct name: nil, graph: nil, alias_index: %{}

  def build(%{"name" => name, "hierarchy" => hierarchy_spec}) do
    graph = :digraph.new([:acyclic])
    graph |> fill_hierarchy(hierarchy_spec)
    alias_index = for n <- :digraph.vertices(graph), as <- n.aliases, into: %{}, do: {as, n}
    %__MODULE__{name: name, graph: graph, alias_index: alias_index}
  end

  defp fill_hierarchy(graph, node_specs) do
    for node_spec <- node_specs do
      node = Node.build(node_spec)
      node_vertex = graph |> :digraph.add_vertex(node, node.label)

      for child_node_vertex <- fill_hierarchy(graph, node_spec["nodes"] || []) do
        graph |> :digraph.add_edge(node_vertex, child_node_vertex)
      end

      node_vertex
    end
  end

  def find_node(%__MODULE__{alias_index: index}, label) do
    case Map.fetch(index, label) do
      {:ok, node} -> {:ok, node}
      :error -> {:error, "Label `#{label}` not found"}
    end
  end

  def get_parent(%__MODULE__{graph: graph}, node) do
    case :digraph.in_neighbours(graph, node) do
      [parent] -> parent
      [] -> nil
    end
  end

  def get_children(%__MODULE__{graph: graph}, node) do
    :digraph.out_neighbours(graph, node)
  end

  def get_root(%__MODULE__{graph: graph}) do
    {:yes, root} = :digraph_utils.arborescence_root(graph)
    root
  end

  def walk_nodes(%__MODULE__{graph: graph} = hierarchy, fun) when is_function(fun, 2) do
    do_walk_nodes([Olap.Hierarchy.get_root(hierarchy)], graph, fun)
  end

  defp do_walk_nodes(nodes, graph, fun) do
    for node <- nodes do
      children_results = graph |> :digraph.out_neighbours(node) |> do_walk_nodes(graph, fun)
      fun.(node, children_results)
    end
  end

  def leaf?(%__MODULE__{graph: graph}, node) do
    :digraph.out_degree(graph, node) == 0
  end
end

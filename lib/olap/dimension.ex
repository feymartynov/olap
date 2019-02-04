defmodule Olap.Dimension do
  defmodule HierarchyLevel do
    defstruct ref: nil, label: nil, aliases: [], weight: 1, nodes: []
  end

  defstruct name: nil, hierarchy: [], leafs: []

  def build(%{"name" => name, "hierarchy" => hierarchy_spec}) do
    {levels, leafs} = build_hierarchy(hierarchy_spec)
    %__MODULE__{name: name, hierarchy: levels, leafs: leafs}
  end

  defp build_hierarchy(nodes) do
    Enum.reduce(Enum.reverse(nodes || []), {[], %{}}, fn node, {levels, leafs} ->
      {inner_levels, inner_leafs} = build_hierarchy(node["nodes"])
      level = build_hierarchy_level(node, inner_levels)

      inner_leafs =
        case map_size(inner_leafs) do
          0 -> Enum.into(level.aliases, %{}, &{&1, level.ref})
          _ -> inner_leafs
        end

      {[level | levels], Map.merge(leafs, inner_leafs)}
    end)
  end

  def build_hierarchy_level(node, inner_levels) do
    %HierarchyLevel{
      ref: make_ref(),
      label: node["label"],
      aliases: [node["label"] | Map.get(node, "aliases", [])],
      weight: node["weight"] || 1,
      nodes: inner_levels
    }
  end

  def find_node(%__MODULE__{hierarchy: hierarchy}, label), do: find_node(hierarchy, label)

  def find_node(levels, label) do
    Enum.reduce_while(levels, {:error, "Label `#{label}` not found"}, fn level, _ ->
      if label in level.aliases do
        {:halt, {:ok, level}}
      else
        case find_node(level.nodes, label) do
          {:ok, node} -> {:halt, {:ok, node}}
          other -> {:cont, other}
        end
      end
    end)
  end
end

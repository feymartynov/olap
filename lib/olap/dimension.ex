defmodule Olap.Dimension do
  defmodule HierarchyLevel do
    defstruct label: nil, aliases: [], weight: 1, items: []
  end

  defstruct name: nil, hierarchy: [], leafs: []

  def build(%{"name" => name, "hierarchy" => hierarchy_spec}) do
    {levels, leafs} = build_hierarchy(hierarchy_spec)
    %__MODULE__{name: name, hierarchy: levels, leafs: leafs}
  end

  defp build_hierarchy(items) do
    Enum.reduce(Enum.reverse(items || []), {[], []}, fn item, {levels, leafs} ->
      aliases = [item["label"] | Map.get(item, "aliases", [])]
      {inner_levels, inner_leafs} = build_hierarchy(item["items"])
      level = %HierarchyLevel{label: item["label"], aliases: aliases, items: inner_levels}
      inner_leafs = if inner_leafs == [], do: aliases, else: inner_leafs
      {[level | levels], leafs ++ inner_leafs}
    end)
  end
end

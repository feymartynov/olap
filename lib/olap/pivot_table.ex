defmodule Olap.PivotTable do
  alias Olap.{Cube, Hierarchy}

  defmodule Dimension do
    defstruct hierarchy: nil, nodes: []
  end

  defstruct name: nil, cube: nil, dimensions: []

  def build(name, %Cube{} = cube, [{_, _}, {_, _}] = dimensions) do
    pivot_dimensions =
      for {dimension_name, labels} <- dimensions do
        hierarchy = cube.dimensions |> Enum.find(&(&1.name == dimension_name))
        {:ok, nodes} = hierarchy |> find_nodes(labels)
        %Dimension{hierarchy: hierarchy, nodes: nodes}
      end

    %__MODULE__{name: name, cube: cube, dimensions: pivot_dimensions}
  end

  defp find_nodes(hierarchy, labels) do
    Enum.reduce_while(Enum.reverse(labels), {:ok, []}, fn label, {:ok, acc} ->
      case Hierarchy.find_node(hierarchy, label) do
        {:ok, node} -> {:cont, {:ok, [node | acc]}}
        other -> {:halt, other}
      end
    end)
  end

  def calculate(%__MODULE__{cube: cube, dimensions: [x, y]}) do
    x_index = cube.dimensions |> Enum.find_index(&(&1.name == x.hierarchy.name))
    y_index = cube.dimensions |> Enum.find_index(&(&1.name == y.hierarchy.name))

    for x_node <- x.nodes do
      for y_node <- y.nodes do
        address =
          for {hierarchy, index} <- Stream.with_index(cube.dimensions) do
            cond do
              index == x_index -> x_node
              index == y_index -> y_node
              true -> Hierarchy.get_root(hierarchy)
            end
          end

        cube |> Cube.consolidate(address)
      end
    end
  end
end

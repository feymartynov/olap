defmodule Olap.PivotTable do
  defmodule Dimension do
    defstruct dimension: nil, nodes: []
  end

  defstruct name: nil, cube: nil, dimensions: []

  def build(name, %Olap.Cube{} = cube, [{_, _}, {_, _}] = dimensions) do
    pivot_dimensions =
      for {dimension_name, labels} <- dimensions do
        dimension = cube.dimensions |> Enum.find(&(&1.name == dimension_name))
        {:ok, nodes} = dimension |> find_nodes(labels)
        %Dimension{dimension: dimension, nodes: nodes}
      end

    %__MODULE__{name: name, cube: cube, dimensions: pivot_dimensions}
  end

  defp find_nodes(dimension, labels) do
    Enum.reduce_while(Enum.reverse(labels), {:ok, []}, fn label, {:ok, acc} ->
      case Olap.Dimension.find_node(dimension, label) do
        {:ok, node} -> {:cont, {:ok, [node | acc]}}
        other -> {:halt, other}
      end
    end)
  end

  def calculate(%__MODULE__{cube: cube, dimensions: [x, y]}) do
    x_index = cube.dimensions |> Enum.find_index(&(&1.name == x.dimension.name))
    y_index = cube.dimensions |> Enum.find_index(&(&1.name == y.dimension.name))

    for x_node <- x.nodes do
      for y_node <- y.nodes do
        address =
          for {dimension, index} <- Stream.with_index(cube.dimensions) do
            cond do
              index == x_index -> x_node
              index == y_index -> y_node
              true -> List.first(dimension.hierarchy)
            end
          end

        cube |> Olap.Cube.consolidate(address)
      end
    end
  end
end

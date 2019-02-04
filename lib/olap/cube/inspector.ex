defmodule Olap.Cube.Inspector do
  alias Olap.Cube

  def slice(%Cube{} = cube, field_name, opts) when is_list(opts) and length(opts) <= 2 do
    dimension_indexes = cube |> dimension_indexes(opts)
    address_ms = cube |> build_slice_ms(dimension_indexes, opts)
    cube.aggregations_table |> :ets.select([{{address_ms, :"$1"}, [], [:"$1"]}]) |> Scribe.print()
  end

  defp dimension_indexes(cube, opts) do
    for {name, depth} <- opts do
      name = to_string(name)
      dimension_index = cube.dimensions |> Enum.find_index(&(&1.field.name == name))
      dimension_index || raise "Dimension `#{name}` is missing in #{inspect(cube)}"
      dimension = cube.dimensions |> Enum.at(dimension_index)
      max_depth = dimension.hierarchy |> Enum.count()

      if depth > max_depth do
        raise "Dimension `#{name}` has only #{max_depth} levels. Required #{depth}"
      end

      dimension_index
    end
  end

  defp build_slice_ms(cube, dimension_indexes, opts) do
    for {_, index} <- Enum.with_index(cube.dimensions) do
      case dimension_indexes |> Enum.find_index(&(&1 == index)) do
        nil -> :_
        opt_index -> List.duplicate(:_, opts |> Enum.at(opt_index) |> elem(1))
      end
    end
  end
end

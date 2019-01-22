defmodule Olap.Types.Integer do
  @behaviour Olap.Type

  alias Olap.Cube.Dimension.HierarchyLevel

  def validate(_, value) when is_integer(value), do: :ok
  def validate(_, value), do: {:error, "Not an integer: `#{inspect(value)}`"}

  def parse_string(_, str) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> {:error, "Failed to parse string `#{str}` as integer"}
    end
  end

  def parse_hierarchy_level_value(field, value) do
    with {:ok, int} <- parse_string(%{}, value) do
      if int > 1 do
        {:ok, int, field}
      else
        {:error, "Integer hierarchy level must be > 1, got #{int}"}
      end
    end
  end

  def get_coordinate(_, value, hierarchy), do: do_get_coordinate(value, hierarchy, [])

  defp do_get_coordinate(_value, [], acc), do: Enum.reverse(acc)

  defp do_get_coordinate(value, [%HierarchyLevel{level: level, include: include} | tail], acc) do
    component = trunc(value / level)
    value = value - component * level
    acc = if include, do: [component | acc], else: acc
    do_get_coordinate(value, tail, acc)
  end
end

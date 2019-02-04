defmodule Olap.Types.Timestamp do
  @behaviour Olap.Type

  alias Olap.Cube.Dimension.HierarchyLevel

  def validate(_, %DateTime{}), do: :ok
  def validate(_, value), do: {:error, "Not a timestamp: `#{inspect(value)}`"}

  def parse_string(_, str) do
    case DateTime.from_iso8601(str) do
      {:ok, result, _utc_offset} ->
        {:ok, result}

      {:error, reason} ->
        {:error, "Failed to parse string `#{str}` as timestamp\nReason: #{inspect(reason)}"}
    end
  end

  @levels ~w(second minute hour day week month quarter year)

  def parse_hierarchy_level_value(field, value, previous_levels) do
    case @levels |> Enum.find_index(&(&1 == value)) do
      nil ->
        {:error, "Bad timestamp hiearchy level #{value}"}

      index ->
        last_level = previous_levels |> List.last()

        if is_nil(last_level) || index > Enum.find_index(@levels, &(&1 == last_level.level)) do
          {:ok, value, field}
        else
          {:error, "`#{value}` can't go after `#{last_level.level}` in timestamp hierarchy"}
        end
    end
  end

  def get_coordinate(_, value, hierarchy) do
    hierarchy
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn
      {%HierarchyLevel{level: level, include: include}, index}, {:ok, acc} ->
        cond do
          level != Enum.at(@levels, index) -> {:halt, {:error, "Bad timestamp level #{level}"}}
          include -> {:cont, {:ok, [get_coordinate_component(value, level) | acc]}}
          true -> {:cont, {:ok, acc}}
        end
    end)
    |> case do
      {:ok, coordinate} -> {:ok, Enum.reverse(coordinate)}
      other -> other
    end
  end

  defp get_coordinate_component(value, "second"), do: value.second
  defp get_coordinate_component(value, "minute"), do: value.minute
  defp get_coordinate_component(value, "hour"), do: value.hour
  defp get_coordinate_component(value, "day"), do: value.day
  defp get_coordinate_component(value, "week"), do: rem(value.day, 7) + 1
  defp get_coordinate_component(value, "month"), do: value.month
  defp get_coordinate_component(value, "quarter"), do: rem(value.month, 3) + 1
  defp get_coordinate_component(value, "year"), do: value.year
end

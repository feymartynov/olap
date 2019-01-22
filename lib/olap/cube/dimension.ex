defmodule Olap.Cube.Dimension do
  defmodule HierarchyLevel do
    defstruct level: nil, include: true, field: nil
  end

  alias Olap.FieldSet
  alias Olap.FieldSet.Field

  defstruct field: nil, hierarchy: []

  def build(%{"field" => field_name, "hierarchy" => hierarchy_spec}, %FieldSet{fields: fields}) do
    with %Field{} = field <- fields[field_name] || {:error, "Missing field `#{field_name}`"},
         {:ok, hierarchy} <- build_hierarchy(hierarchy_spec, field) do
      {:ok, %__MODULE__{field: field, hierarchy: hierarchy}}
    end
  end

  defp build_hierarchy(specs, field), do: build_hierarchy(specs, field, [])
  defp build_hierarchy([], _field, acc), do: {:ok, Enum.reverse(acc)}

  defp build_hierarchy([spec | tail], field, acc) do
    with :ok <- validate_level_spec(spec),
         {:ok, value, next_field} <- field |> parse_hierarchy_level_value(spec["level"]) do
      level = %HierarchyLevel{level: value, include: spec["include"], field: field}
      build_hierarchy(tail, next_field, [level | acc])
    end
  end

  defp validate_level_spec(spec) when is_map(spec) do
    with :ok <- validate_level(spec["level"]),
         :ok <- validate_include(spec["include"]),
         do: :ok
  end

  defp validate_level_spec(_) do
    {:error, "Level spec is not a map"}
  end

  defp validate_level(nil), do: {:error, "Level value not specified"}
  defp validate_level(_), do: :ok

  defp validate_include(value) when is_boolean(value), do: :ok
  defp validate_include(_), do: {:error, "`include` is not a boolean"}

  defp parse_hierarchy_level_value(_, nil) do
    {:error, "Null level value is not allowed"}
  end

  defp parse_hierarchy_level_value(%Field{type: type} = field, str) do
    apply(type, :parse_hierarchy_level_value, [field, str])
  end

  def get_coordinate(%__MODULE__{field: field, hierarchy: hierarchy}, value) do
    apply(field.type, :get_coordinate, [field.settings, value, hierarchy])
  end
end

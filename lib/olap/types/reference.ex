defmodule Olap.Types.Reference do
  @behaviour Olap.Type

  alias Olap.{Reference, FieldSet.Field, Cube.Dimension.HierarchyLevel}

  defstruct reference: nil

  def build_settings(spec) when is_map(spec) do
    case spec["reference"] do
      nil ->
        {:error, "`reference` not specified"}

      name ->
        case Reference.get(name) do
          nil -> {:error, "Reference `#{spec["reference"]}` is not defined"}
          :stub -> {:ok, %__MODULE__{reference: fn -> Reference.get(name) end}}
          %Reference{} = reference -> {:ok, %__MODULE__{reference: fn -> reference end}}
        end
    end
  end

  def validate(%__MODULE__{reference: reference}, value) do
    with :ok <- Olap.Types.Integer.validate(%{}, value) do
      case reference.() |> Reference.fetch(value) do
        {:ok, _} -> :ok
        :error -> {:error, "Missing id `#{value}` in reference `#{reference.().name}`"}
      end
    end
  end

  defdelegate parse_string(settings, str), to: Olap.Types.Integer

  def parse_hierarchy_level_value(%Field{settings: %__MODULE__{reference: reference}}, value) do
    case reference.().field_set.fields[value] do
      %Field{} = field -> {:ok, field, field}
      nil -> {:error, "Field `#{value}` not found in reference `#{reference.().name}`"}
    end
  end

  def get_coordinate(_, value, hierarchy) do
    do_get_coordinate(value, hierarchy, [])
  end

  defp do_get_coordinate(value, [], acc), do: {:ok, Enum.reverse([value | acc])}

  defp do_get_coordinate(value, [level | tail], acc) do
    %HierarchyLevel{field: %Field{settings: %__MODULE__{reference: reference}}} = level
    level_name = level.level.name

    case reference.() |> Reference.fetch(value) do
      {:ok, item} ->
        case item[level_name] do
          nil -> do_get_coordinate(value, [], acc)
          id -> do_get_coordinate(id, tail, [value | acc])
        end

      :error ->
        {:error, "Missing id `#{value}` in reference `#{reference.().name}`"}
    end
  end
end

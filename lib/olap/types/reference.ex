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

  def parse_hierarchy_level_value(%Field{name: name} = field, value, []) do
    if name == value do
      {:ok, field, field}
    else
      reason =
        "The first level of reference hierarchy must be the field itself – `#{name}`." <>
          "Got `#{value}`"

      {:error, reason}
    end
  end

  def parse_hierarchy_level_value(%Field{settings: %__MODULE__{reference: reference}}, value, _) do
    case reference.().field_set.fields[value] do
      %Field{} = field -> {:ok, field, field}
      nil -> {:error, "Field `#{value}` not found in reference `#{reference.().name}`"}
    end
  end

  def get_coordinate(_, value, [head | _] = hierarchy) do
    do_get_coordinate(hierarchy, %{head.level.name => value}, [])
  end

  defp do_get_coordinate([], _, acc), do: {:ok, Enum.reverse(acc)}

  defp do_get_coordinate([head | tail], prev_item, acc) do
    %HierarchyLevel{
      level: %Field{name: level_name},
      field: %Field{settings: %__MODULE__{reference: reference}},
      include: include
    } = head

    id = prev_item[level_name]

    case reference.() |> get_reference_item(id) do
      {:ok, item} -> do_get_coordinate(tail, item, if(include, do: [id | acc], else: acc))
      :empty_id -> do_get_coordinate([], nil, acc)
      :missing_item -> {:error, "Missing id `#{id}` in reference `#{reference.().name}`"}
    end
  end

  defp get_reference_item(_reference, nil), do: :empty_id

  defp get_reference_item(reference, id) do
    case reference |> Reference.fetch(id) do
      {:ok, item} -> {:ok, item}
      :error -> :missing_item
    end
  end
end

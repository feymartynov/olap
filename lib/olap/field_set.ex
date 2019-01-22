defmodule Olap.FieldSet do
  alias __MODULE__.Field

  defstruct fields: %{}

  def build(field_specs) when is_list(field_specs) do
    with {:ok, fields} <- build_fields(field_specs) do
      {:ok, %__MODULE__{fields: fields}}
    end
  end

  defp build_fields(specs) do
    Enum.reduce_while(specs, {:ok, %{}}, fn field_spec, {:ok, acc} ->
      case Field.build(field_spec) do
        {:ok, field} -> {:cont, {:ok, Map.put_new(acc, field.name, field)}}
        other -> {:halt, other}
      end
    end)
  end

  def validate(%__MODULE__{fields: fields}, item) when is_map(item) do
    Enum.reduce_while(item, :ok, fn
      {"id", id}, _ when is_integer(id) ->
        {:cont, :ok}

      {"id", id}, _ ->
        {:halt, {:error, "`id` is not integer, got #{inspect(id)}"}}

      {field_name, value}, _ ->
        case fields[field_name] do
          nil ->
            {:halt, {:error, "Unknown field `#{field_name}`"}}

          field ->
            case field |> Field.validate(value) do
              :ok -> {:cont, :ok}
              {:error, reason} -> {:halt, {:error, reason}}
            end
        end
    end)
  end
end

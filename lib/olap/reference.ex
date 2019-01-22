defmodule Olap.Reference do
  @behaviour Access

  alias Olap.FieldSet

  defstruct name: nil, field_set: nil, table: nil

  def init(specs) do
    :ets.new(:references, [:named_table, :public, read_concurrency: true])

    for %{"name" => name} <- specs, do: register(name, :stub)

    Enum.reduce_while(specs, :ok, fn spec, _ ->
      with {:ok, reference} <- build(spec),
           :ok <- register(reference) do
        {:cont, :ok}
      else
        other -> {:halt, other}
      end
    end)
  end

  def build(%{"name" => name, "fields" => fields_spec}) do
    with {:ok, field_set} <- FieldSet.build(fields_spec) do
      table = :ets.new(:reference, [:public, read_concurrency: true])
      {:ok, %__MODULE__{name: name, field_set: field_set, table: table}}
    end
  end

  defp register(%__MODULE__{name: name} = reference), do: register(name, reference)
  defp register(name, reference), do: :ets.insert(:references, {name, reference}) && :ok

  def get(name) do
    case :ets.lookup(:references, name) do
      [{^name, reference}] -> reference
      [] -> nil
    end
  end

  def put(%__MODULE__{table: table, field_set: field_set}, item) when is_map(item) do
    with id when not is_nil(id) <- item["id"],
         :ok <- field_set |> FieldSet.validate(item),
         true <- :ets.insert(table, {id, item}) do
      :ok
    else
      nil -> {:error, "Missing `id` field in #{inspect(item)}"}
      other -> other
    end
  end

  def fetch(%__MODULE__{table: table}, id) do
    case :ets.lookup(table, id) do
      [{^id, value}] -> {:ok, value}
      [] -> :error
    end
  end

  def get_and_update(%__MODULE__{name: name, table: table} = reference, id, fun) do
    value =
      case reference |> fetch(id) do
        {:ok, value} -> value
        :error -> nil
      end

    case fun.(value) do
      {get_value, updated_value} ->
        updated_value = updated_value |> Map.put("id", id)

        case reference |> put(updated_value) do
          :ok ->
            {get_value, reference}

          {:error, reason} ->
            raise "Failed to put item to reference #{name}.\n" <>
                    "Item: #{inspect(updated_value)}.\nReason: #{inspect(reason)}"
        end

      :pop ->
        :ets.delete(table, id)
        {value, reference}
    end
  end

  def pop(%__MODULE__{table: table} = reference, id) do
    case reference |> fetch(id) do
      {:ok, value} ->
        :ets.delete(table, id)
        {value, reference}

      :error ->
        {nil, reference}
    end
  end
end

defimpl Inspect, for: Olap.Reference do
  import Inspect.Algebra

  def inspect(reference, _) do
    concat(["#Reference<", reference.name, ">"])
  end
end

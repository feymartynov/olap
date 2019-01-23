defmodule Olap.Seeds do
  require Logger

  alias NimbleCSV.RFC4180, as: CSV
  alias Olap.{Reference, Cube}

  @limits [references: 10, cubes: 100]
  @id_field_spec %{"name" => "id", "type" => "integer"}

  def generate(config) do
    for {key, n} <- @limits, %{"name" => name, "fields" => fields} <- config[to_string(key)] do
      stream = 0..n |> Stream.map(fn id -> [id | Enum.map(fields, &seed_field(&1, id, name))] end)
      File.write!(path(key, name), CSV.dump_to_iodata(stream), [:write, :binary])
    end
  end

  defp seed_field(%{"type" => "integer"}, id, _), do: id
  defp seed_field(%{"type" => "string", "name" => name}, id, _), do: "#{name} #{id}"
  defp seed_field(%{"type" => "timestamp"}, _, _), do: DateTime.utc_now() |> DateTime.to_iso8601()
  defp seed_field(%{"type" => "money"}, id, _), do: id
  defp seed_field(%{"type" => "reference", "reference" => name}, _, name), do: nil
  defp seed_field(%{"type" => "reference"}, id, _), do: rem(id, @limits[:references])
  defp seed_field(_, _, _), do: nil

  def load(config) do
    for {key, _} <- @limits, %{"name" => name, "fields" => fields} <- config[to_string(key)] do
      path = path(key, name)

      if File.exists?(path) do
        path
        |> File.stream!(read_ahead: 100_000)
        |> CSV.parse_stream(headers: false)
        |> Stream.map(&cast_fields([@id_field_spec | fields], &1))
        |> put(key, name)
        |> Stream.each(fn
          {:ok, _} -> :ok
          other -> raise "Import error `#{key}` `#{name}`: #{inspect(other)}"
        end)
        |> Stream.run()
      end
    end

    :ok
  end

  defp cast_fields(fields, values) when length(fields) == length(values) do
    for {field, value} <- Enum.zip(fields, values), into: %{} do
      {field["name"], cast_field(field, value)}
    end
  end

  defp cast_field(_, ""), do: nil
  defp cast_field(%{"type" => "integer"}, x), do: String.to_integer(x)
  defp cast_field(%{"type" => "string"}, x), do: x
  defp cast_field(%{"type" => "timestamp"}, x), do: x |> DateTime.from_iso8601() |> elem(1)
  defp cast_field(%{"type" => "money", "currency" => cur}, x), do: Money.parse!(x, cur)
  defp cast_field(%{"type" => "reference"}, x), do: String.to_integer(x)
  defp cast_field(field, _), do: raise("Bad field cast: #{inspect(field)}")

  defp put(stream, :references, name) do
    case Reference.get(name) do
      %Reference{} = reference -> stream |> Stream.map(&Reference.put(reference, &1))
      nil -> raise "Reference `#{name}` not found"
    end
  end

  defp put(stream, :cubes, name) do
    case Cube.get(name) do
      %Cube{} = cube -> stream |> Stream.chunk_every(1000) |> Stream.map(&Cube.put(cube, &1))
      nil -> raise "Cube `#{name}` not found"
    end
  end

  defp path(key, name), do: Path.join(["priv", "seeds", to_string(key), "#{name}.csv"])
end

defmodule Olap.Types.String do
  @behaviour Olap.Type

  def validate(_, value) when is_bitstring(value), do: :ok
  def validate(_, value), do: {:error, "Not a string: `#{inspect(value)}`"}

  def parse_string(_, str), do: {:ok, str}

  def parse_hierarchy_level_value(_field, _value) do
    {:error, "String hierarchy can't contain any levels"}
  end

  def get_coordinate(_, value, _hierarchy), do: [value]
end

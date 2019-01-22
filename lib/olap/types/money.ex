defmodule Olap.Types.Money do
  @behaviour Olap.Type

  alias Olap.FieldSet.Field
  alias Olap.Cube.Dimension.HierarchyLevel

  defstruct currency: nil

  def build_settings(spec) when is_map(spec) do
    case spec["currency"] do
      nil -> {:error, "`currency` not specified"}
      currency -> {:ok, %__MODULE__{currency: currency}}
    end
  end

  def validate(%__MODULE__{currency: currency}, %Money{currency: value_currency}) do
    if to_string(value_currency) == currency do
      :ok
    else
      {:error, "Bad currency for money value. Expected #{currency}, got #{value_currency}"}
    end
  end

  def validate(_, value) do
    {:error, "Bad money value #{inspect(value)}"}
  end

  def parse_string(%__MODULE__{currency: currency}, str) do
    case Money.parse(str, currency) do
      {:ok, result} -> {:ok, result}
      :error -> {:error, "Failed to parse string `#{str}` as money type"}
    end
  end

  def parse_hierarchy_level_value(%Field{settings: %__MODULE__{}} = field, value) do
    one = Money.new(1, field.settings.currency)

    with {:ok, money} <- parse_string(field.settings, value) do
      if money > one do
        {:ok, money, field}
      else
        {:error, "Integer hierarchy level must be > #{one}, got #{money}"}
      end
    end
  end

  def get_coordinate(_, value, hierarchy), do: do_get_coordinate(value, hierarchy, [])

  defp do_get_coordinate(_value, [], acc), do: Enum.reverse(acc)

  defp do_get_coordinate(value, [%HierarchyLevel{level: level, include: include} | tail], acc) do
    component = Money.new(trunc(value.amount / level.amount), value.currency)
    value = Money.new(value.amount - component.amount * level.amount, value.currency)
    acc = if include, do: [component | acc], else: acc
    do_get_coordinate(value, tail, acc)
  end

  def add(%Money{amount: lhs, currency: currency}, %Money{amount: rhs, currency: currency}) do
    Money.new(lhs + rhs, currency)
  end

  def add(%Money{currency: currency1}, %Money{currency: currency2}) do
    raise "Currency exchange not supported. Attempted to add #{currency2} to #{currency1}"
  end

  def add(lhs, rhs) do
    raise "Expected %Money{}, got #{inspect(lhs)} and #{inspect(rhs)}`"
  end
end

defmodule Olap.Formula do
  alias Olap.FieldSet
  alias __MODULE__.{AST, Parser}

  defstruct str: nil, ast: nil

  def build(str, %FieldSet{} = field_set) when is_bitstring(str) do
    with {:ok, ast} <- Parser.parse(str),
         {:ok, ast} <- ast |> AST.Transformer.transform(field_set) do
      {:ok, %__MODULE__{str: str, ast: ast}}
    end
  end

  def evaluate(%__MODULE__{ast: ast}, items) when is_list(items) do
    reduce_ast(ast, items)
  end

  defp reduce_ast(%AST.Field{field: %FieldSet.Field{name: name}}, items) do
    {:ok, items |> Enum.map(& &1[name])}
  end

  defp reduce_ast(%AST.Function{impl: impl, args: args}, items) do
    args
    |> Enum.reduce_while({:ok, []}, fn arg, {:ok, acc} ->
      case reduce_ast(arg, items) do
        {:ok, []} -> {:halt, {:ok, nil}}
        {:ok, result} -> {:cont, {:ok, [result | acc]}}
        other -> {:halt, other}
      end
    end)
    |> case do
      {:ok, nil} -> {:ok, nil}
      {:ok, args} -> args |> Enum.reverse() |> impl.()
      other -> other
    end
  end
end

defimpl Inspect, for: Olap.Formula do
  import Inspect.Algebra

  def inspect(formula, _) do
    concat(["#Formula<", formula.str, ">"])
  end
end

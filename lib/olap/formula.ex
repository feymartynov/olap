defmodule Olap.Formula do
  alias __MODULE__.{AST, Parser}

  defstruct str: nil, ast: nil

  def build(str) when is_bitstring(str) do
    with {:ok, ast} <- Parser.parse(str),
         {:ok, ast} <- AST.Transformer.transform(ast) do
      {:ok, %__MODULE__{str: str, ast: ast}}
    end
  end

  def evaluate(%__MODULE__{ast: ast}) do
    case reduce_ast(ast) do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:ok, nil}
      other -> other
    end
  end

  defp reduce_ast(%AST.Constant{value: value}) do
    {:ok, value}
  end

  defp reduce_ast(%AST.FunctionCall{mod: mod, args: args}) do
    args
    |> Enum.reduce_while({:ok, []}, fn arg, {:ok, acc} ->
      case reduce_ast(arg) do
        {:ok, []} -> {:halt, {:ok, nil}}
        {:ok, result} -> {:cont, {:ok, [result | acc]}}
        other -> {:halt, other}
      end
    end)
    |> case do
      {:ok, nil} -> {:ok, nil}
      {:ok, args} -> apply(mod, :call, [Enum.reverse(args)])
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

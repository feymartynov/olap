defmodule Olap.Formula.AST.Transformer do
  alias Olap.Formula.{AST, Function}
  alias Olap.Formula.Functions.{Sum, Sub, Mul, Div, Pow, Gt, Gte, Lt, Lte, Eq, Neq}

  @zero %AST.Constant{value: 0.0, type: :number}

  def transform({:number, [value]}) do
    {:ok, %AST.Constant{value: value, type: :number}}
  end

  def transform({:identifier, [value]}) do
    {:ok, %AST.Constant{value: value, type: :identitifer}}
  end

  def transform({:function_call, [{:identifier, [name]} | args]}) do
    with {:ok, args} <- transform_args(args),
         {:ok, mod} <- Function.get_mod(name),
         do: {:ok, %AST.FunctionCall{mod: mod, args: args}}
  end

  def transform({:unary_prefix_operator, [?-, arg]}) do
    with {:ok, arg} <- transform(arg) do
      {:ok, %AST.FunctionCall{mod: Sub, args: [@zero, arg]}}
    end
  end

  def transform({:binary_operator, [left, operator, right]}) do
    mod =
      case operator do
        ?+ -> Sum
        ?- -> Sub
        ?* -> Mul
        ?/ -> Div
        ?^ -> Pow
        ?> -> Gt
        ">=" -> Gte
        ?< -> Lt
        "<=" -> Lte
        ?= -> Eq
        "<>" -> Neq
      end

    with {:ok, left} <- transform(left), {:ok, right} <- transform(right) do
      {:ok, %AST.FunctionCall{mod: mod, args: [left, right]}}
    end
  end

  defp transform_args(args) do
    Enum.reduce_while(Enum.reverse(args), {:ok, []}, fn arg, {:ok, acc} ->
      case transform(arg) do
        {:ok, arg} -> {:cont, {:ok, [arg | acc]}}
        other -> {:halt, other}
      end
    end)
  end
end

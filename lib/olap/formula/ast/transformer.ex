defmodule Olap.Formula.AST.Transformer do
  alias Olap.FieldSet.Field
  alias Olap.Formula.{AST, Function}

  def transform({:field, [name]}, field_set) do
    case field_set.fields |> Map.fetch(name) do
      {:ok, field} -> {:ok, %AST.Field{field: field}}
      :error -> {:error, "Field `#{name}` is not defined"}
    end
  end

  def transform({:fun, [name | args]}, field_set) do
    with {:ok, args} <- args |> transform_args(field_set),
         arg_types = args |> Enum.map(&arg_type/1),
         {:ok, function_mod} <- Function.get(name),
         {:ok, signature, impl} <- function_mod |> Function.find_signature(arg_types),
         do: {:ok, %AST.Function{name: name, signature: signature, impl: impl, args: args}}
  end

  defp transform_args(args, field_set) do
    Enum.reduce_while(args, {:ok, []}, fn arg, {:ok, acc} ->
      case transform(arg, field_set) do
        {:ok, type} -> {:cont, {:ok, acc ++ [type]}}
        other -> {:halt, other}
      end
    end)
  end

  defp arg_type(%AST.Field{field: %Field{type: type}}), do: type
  defp arg_type(%AST.Function{signature: {_, return_type}}), do: return_type
end

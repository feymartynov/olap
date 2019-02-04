defmodule Olap.Formula.AST.Transformer do
  alias Olap.FieldSet.Field
  alias Olap.Formula.{AST, Function}

  def transform(ast, field_set) do
    case transform(ast, field_set, [], nil) do
      {:ok, ast, variables, return_type} -> {:ok, ast, Enum.reverse(variables), return_type}
      other -> other
    end
  end

  defp transform({:field, [name]}, field_set, variables, return_type) do
    case field_set.fields |> Map.fetch(name) do
      {:ok, field} ->
        {:ok, %AST.Field{field: field}, [field | variables], return_type || field.type}

      :error ->
        {:error, "Field `#{name}` is not defined"}
    end
  end

  defp transform({:fun, [name | args]}, field_set, variables, return_type) do
    with {:ok, args} <- args |> transform_args(field_set),
         arg_types = args |> Enum.map(&arg_type/1),
         {:ok, {_, ret} = signature, impl} <- Function.find_signature(name, arg_types) do
      function = %AST.Function{name: name, signature: signature, impl: impl, args: args}
      {:ok, function, variables, return_type || ret}
    end
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

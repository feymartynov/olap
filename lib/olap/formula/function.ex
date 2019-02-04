defmodule Olap.Formula.Function do
  @functions Application.get_env(:olap, :functions)

  def get(name) do
    case @functions |> Map.fetch(name) do
      {:ok, signatures} -> {:ok, signatures}
      :error -> {:error, "Function `#{name}` is not defined"}
    end
  end

  def find_signature(name, arg_types) do
    with {:ok, signatures} <- get(name) do
      case Enum.find(signatures, fn {{types, _}, _} -> types == arg_types end) do
        nil ->
          {:error, "No signature matched for function `#{name}` with args #{inspect(arg_types)}"}

        {signature, impl} ->
          {:ok, signature, impl}
      end
    end
  end
end

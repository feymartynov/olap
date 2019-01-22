defmodule Olap.Formula.Function do
  @type signature :: {args :: [atom()], return :: atom()}
  @callback signatures() :: %{signature => ([term()] -> term())}

  @functions Application.get_env(:olap, :functions)

  def get(name) do
    case @functions |> Map.fetch(name) do
      {:ok, mod} -> {:ok, mod}
      :error -> {:error, "Function `#{name}` is not defined"}
    end
  end

  def find_signature(mod, arg_types) do
    signatures = mod |> apply(:signatures, [])

    case Enum.find(signatures, fn {{types, _}, _} -> types == arg_types end) do
      nil -> {:error, "No signature matched for function #{mod} with args #{inspect(arg_types)}"}
      {signature, impl} -> {:ok, signature, impl}
    end
  end
end

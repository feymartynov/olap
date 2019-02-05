defmodule Olap.Formula.Function do
  @callback call(args :: [any]) :: {:ok, result :: any} | {:error, reason :: any}

  @functions Application.get_env(:olap, :functions)

  def get_mod(name) do
    case @functions |> Map.fetch(name) do
      {:ok, mod} -> {:ok, mod}
      :error -> {:error, "Function `#{name}` is not defined"}
    end
  end
end

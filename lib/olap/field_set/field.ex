defmodule Olap.FieldSet.Field do
  defstruct name: nil, type: nil, settings: %{}

  def build(%{"name" => name, "type" => type} = spec) do
    with {:ok, type_mod} <- get_type_mod(type, name),
         {:ok, settings} <- build_settings(type_mod, spec),
         do: {:ok, %__MODULE__{name: name, type: type_mod, settings: settings}}
  end

  defp build_settings(type, spec) do
    if {:build_settings, 1} in type.module_info[:exports] do
      apply(type, :build_settings, [spec])
    else
      {:ok, %{}}
    end
  end

  def get_type_mod(type, name) do
    case Application.get_env(:olap, :types)[type] do
      nil -> {:error, "Unknown type #{type} for field #{name}"}
      type_mod -> {:ok, type_mod}
    end
  end

  def validate(_, nil), do: :ok

  def validate(%__MODULE__{type: type, settings: settings}, value) do
    apply(type, :validate, [settings, value])
  end
end

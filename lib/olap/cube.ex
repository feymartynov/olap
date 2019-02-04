defmodule Olap.Cube do
  defstruct name: nil, dimensions: [], table: nil

  def build(%{"name" => name, "dimensions" => dimension_names}, dimensions) do
    cube_dimensions = for dimension_name <- dimension_names, do: dimensions[dimension_name]
    table = :ets.new(:cube, [])
    %__MODULE__{name: name, dimensions: cube_dimensions, table: table}
  end

  def put(%__MODULE__{} = cube, address, value) when is_list(address) do
    with :ok <- cube |> validate_address(address) do
      :ets.insert(cube.table, {address, value})
      :ok
    end
  end

  defp validate_address(%__MODULE__{dimensions: dims}, addr) when length(dims) != length(addr) do
    {:error, "Address must have exactly #{length(dims)} components, got #{length(addr)}"}
  end

  defp validate_address(%__MODULE__{dimensions: dimensions}, address) do
    Enum.reduce_while(Enum.zip(address, dimensions), :ok, fn {label, dimension}, _ ->
      if label in dimension.leafs do
        {:cont, :ok}
      else
        {:halt, {:error, "No leaf `#{label}` in dimension `#{dimension.name}`"}}
      end
    end)
  end
end

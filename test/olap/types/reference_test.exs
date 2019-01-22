defmodule Olap.Type.ReferenceTest do
  use ExUnit.Case
  alias Olap.{Reference, Cube, Types}

  def put_item(reference_name, item) do
    :ok = reference_name |> Reference.get() |> Reference.put(item)
  end

  test "get coordinate" do
    "countries" |> put_item(%{"id" => 5, "name" => "Russia"})
    "regions" |> put_item(%{"id" => 4, "name" => "Moscow oblast", "country" => 5})
    "cities" |> put_item(%{"id" => 3, "name" => "Khimki", "region" => 4})
    "addresses" |> put_item(%{"id" => 2, "street_address" => "foo", "city" => 3})
    "customers" |> put_item(%{"id" => 1, "name" => "Fey", "address" => 2})

    cube = Cube.get("sales")
    field = cube.field_set.fields["customer"]
    dimension = cube.dimensions |> Enum.find(&(&1.field.name == "customer"))
    assert {:ok, result} = Types.Reference.get_coordinate(field.settings, 1, dimension.hierarchy)
    assert result == [1, 2, 3, 4, 5]
  end
end

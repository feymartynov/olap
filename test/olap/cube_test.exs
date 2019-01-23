defmodule Olap.CubeTest do
  use ExUnit.Case
  alias Olap.{Cube, Reference}

  def put_item(reference_name, item) do
    :ok = reference_name |> Reference.get() |> Reference.put(item)
  end

  test "save and retrieve value" do
    "branches" |> put_item(%{"id" => 1, "name" => "Craftyarnya"})
    "customers" |> put_item(%{"id" => 2, "name" => "Fey"})
    "products" |> put_item(%{"id" => 3, "name" => "Beer"})

    sale = %{
      "id" => 1234,
      "timestamp" => "2019-01-19T02:53:47Z" |> DateTime.from_iso8601() |> elem(1),
      "branch" => 1,
      "customer" => 2,
      "product" => 3,
      "price" => Money.new(250_00, "RUB"),
      "quantity" => 2,
      "total_amount" => Money.new(500_00, "RUB")
    }

    cube = Cube.get("sales")
    assert :ok = cube |> Cube.put([sale])
    assert {:ok, address} = cube |> Cube.get_address(sale)
    assert %{"id" => 1234} = cube |> Cube.get(address)
  end
end

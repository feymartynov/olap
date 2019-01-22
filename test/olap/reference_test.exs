defmodule Olap.ReferenceTest do
  use ExUnit.Case
  alias Olap.Reference

  test "save and retrieve value" do
    reference = Reference.get("countries")
    reference |> Access.get_and_update(123, fn nil -> {nil, %{"name" => "Russia"}} end)
    assert reference[123] == %{"id" => 123, "name" => "Russia"}
  end
end

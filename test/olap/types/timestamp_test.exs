defmodule Olap.Types.TimestampTest do
  use ExUnit.Case
  alias Olap.{Cube, Types}

  test "get coordinate" do
    cube = Cube.get("sales")
    field = cube.field_set.fields["timestamp"]
    dimension = cube.dimensions |> Enum.find(&(&1.field.name == "timestamp"))
    {:ok, dt, 0} = DateTime.from_iso8601("2019-01-19T02:35:48Z")
    assert {:ok, result} = Types.Timestamp.get_coordinate(field.settings, dt, dimension.hierarchy)
    assert result == [19, 3, 1, 1, 2019]
  end
end

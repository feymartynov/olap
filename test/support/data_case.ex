defmodule Olap.DataCase do
  use ExUnit.CaseTemplate

  setup do
    {:ok, config} = Olap.config()

    case :cubes |> :ets.whereis() do
      :undefined -> :noop
      ref -> :ets.delete(ref)
    end

    Olap.init_cubes(config["cubes"])
    {:ok, config: config}
  end
end

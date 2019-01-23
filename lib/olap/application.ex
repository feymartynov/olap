defmodule Olap.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    with :ok <- Olap.init() do
      children = [{Task.Supervisor, name: Olap.TaskSupervisor}]
      opts = [strategy: :one_for_one, name: Olap.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
end

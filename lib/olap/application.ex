defmodule Olap.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    with {:ok, config} <- config() do
      children = [
        {Task.Supervisor, name: Olap.TaskSupervisor},
        {Olap.Workspace, [:default, config]}
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: Olap.Supervisor)
    end
  end

  def config do
    :olap |> Application.get_env(:config_path) |> YamlElixir.read_from_file()
  end
end

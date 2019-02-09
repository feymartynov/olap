defmodule Olap.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    with {:ok, config} <- config() do
      children =
        [
          {Task.Supervisor, name: Olap.TaskSupervisor},
          {Olap.Workspace, [:default, config]},
          {Olap.Api.Endpoint, []}
        ] ++ env_specific_children(Mix.env())

      Supervisor.start_link(children, strategy: :one_for_one, name: Olap.Supervisor)
    end
  end

  def config do
    :olap |> Application.get_env(:config_path) |> YamlElixir.read_from_file()
  end

  def env_specific_children(:dev), do: [Supervisor.Spec.worker(CodeReloader.Server, [])]
  def env_specific_children(_), do: []
end

defmodule Olap.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    with :ok <- init() do
      children = [{Task.Supervisor, name: Olap.TaskSupervisor}]
      opts = [strategy: :one_for_one, name: Olap.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

  @config_path Application.get_env(:olap, :config_path)

  defp init do
    with {:ok, config} <- YamlElixir.read_from_file(@config_path),
         :ok <- Olap.Reference.init(config["references"]),
         :ok <- Olap.Cube.init(config["cubes"]),
         do: :ok
  end
end

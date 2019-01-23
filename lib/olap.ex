defmodule Olap do
  def config do
    :olap |> Application.get_env(:config_path) |> YamlElixir.read_from_file()
  end

  def init do
    with {:ok, config} <- config(),
         :ok <- Olap.Reference.init(config["references"]),
         :ok <- Olap.Cube.init(config["cubes"]),
         do: :ok
  end

  def load_seeds do
    with {:ok, config} <- config(), do: Olap.Seeds.load(config)
  end
end

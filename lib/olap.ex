defmodule Olap do
  def config do
    :olap |> Application.get_env(:config_path) |> YamlElixir.read_from_file()
  end

  def init do
    with {:ok, _config} <- config(),
         do: :ok
  end
end

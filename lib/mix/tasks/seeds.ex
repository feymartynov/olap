defmodule Mix.Tasks.Seeds do
  use Mix.Task

  @shortdoc "Generates seed data"
  def run(_) do
    with {:ok, config} <- Olap.config() do
      Olap.Seeds.generate(config)
    end
  end
end

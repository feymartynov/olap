defmodule Olap.MixProject do
  use Mix.Project

  def project do
    [
      app: :olap,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {Olap.Application, []}
    ]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 2.1"},
      {:nimble_parsec, "~> 0.5"},
      {:plug, "~> 1.7"},
      {:cowboy, "~> 2.6"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:params, "~> 2.1"},
      {:code_reloader, github: "gravityblast/code_reloader", only: :dev}
    ]
  end
end

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
      {:nimble_parsec, "~> 0.5"}
    ]
  end
end

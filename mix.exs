defmodule Olap.MixProject do
  use Mix.Project

  def project do
    [
      app: :olap,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Olap.Application, []}
    ]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 2.1"},
      {:money, "~> 1.3"},
      {:timex, "~> 3.5"},
      {:nimble_parsec, "~> 0.5"},
      {:nimble_csv, "~> 0.3"}
    ]
  end
end

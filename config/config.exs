use Mix.Config

config :money,
  default_currency: :RUB,
  separator: ".",
  delimeter: ",",
  symbol: false,
  symbol_on_right: true,
  symbol_space: false

config :olap,
  config_path: "config.yml",
  types: %{
    "integer" => Olap.Types.Integer,
    "string" => Olap.Types.String,
    "timestamp" => Olap.Types.Timestamp,
    "money" => Olap.Types.Money,
    "reference" => Olap.Types.Reference
  },
  functions: %{
    "sum" => Olap.Formula.Functions.Sum
  }

import_config "#{Mix.env()}.exs"

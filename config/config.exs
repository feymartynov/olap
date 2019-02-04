use Mix.Config

alias Olap.Types
alias Olap.Formula.Functions

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
    "integer" => Types.Integer,
    "string" => Types.String,
    "timestamp" => Types.Timestamp,
    "money" => Types.Money,
    "reference" => Types.Reference
  },
  functions: %{
    "sum" => %{
      {[Types.Integer], Types.Integer} => &Functions.Sum.sum_int/1,
      {[Types.Money], Types.Money} => &Functions.Sum.sum_money/1
    }
  }

import_config "#{Mix.env()}.exs"

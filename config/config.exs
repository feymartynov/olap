use Mix.Config

alias Olap.Formula.Functions

config :olap,
  config_path: "config.yml",
  functions: %{
    "sum" => Functions.Sum,
    "sub" => Functions.Sub,
    "mul" => Functions.Mul,
    "div" => Functions.Div,
    "mod" => Functions.Mod,
    "pow" => Functions.Pow,
    "if" => Funtions.If,
    "count" => Functions.Count,
    "max" => Functions.Max,
    "min" => Functions.Min,
    "average" => Functions.Average,
    "round" => Functions.Round,
    "roundup" => Functions.Roundup,
    "rounddown" => Functions.Rounddown,
    "and" => Functions.And,
    "or" => Functions.Or,
    "not" => Functions.Not,
    "gt" => Functions.Gt,
    "gte" => Functions.Gte,
    "lt" => Functions.Lt,
    "lte" => Functions.Lte,
    "eq" => Functions.Eq,
    "neq" => Functions.Neq
  }

config :olap, Olap.Api.Endpoint, port: 4000

import_config "#{Mix.env()}.exs"

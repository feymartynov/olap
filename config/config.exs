use Mix.Config

config :olap,
  config_path: "config.yml"

import_config "#{Mix.env()}.exs"

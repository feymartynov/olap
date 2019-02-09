defmodule Olap.Api.Endpoint do
  use Plug.Router
  require Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    with {:ok, [port: port] = config} <- Application.fetch_env(:olap, __MODULE__) do
      Logger.info("Starting server at http://localhost:#{port}/")
      Plug.Adapters.Cowboy.http(__MODULE__, [], config)
    end
  end

  def config(:reloadable_compilers), do: [:elixir]

  if Mix.env() == :dev do
    plug(CodeReloader.Plug, endpoint: __MODULE__)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  forward("/api/v1", to: Olap.Api.Router)

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end

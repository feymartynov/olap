defmodule Olap.Api.AssignWorkspace do
  import Plug.Conn

  def init(opts), do: {:ok, opts}

  def call(conn, _opts) do
    workspace = conn |> get_req_header("x-workspace") |> List.first()
    conn |> assign(:workspace, workspace || :default)
  end
end

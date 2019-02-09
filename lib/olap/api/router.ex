defmodule Olap.Api.Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ~w(application/json), json_decoder: Jason)
  plug(Olap.Api.AssignWorkspace)
  plug(:dispatch)

  get("/cubes", do: Olap.Api.CubeController.index(conn))
  get("/cubes/:name", do: Olap.Api.CubeController.show(conn))

  get("/hierarchies", do: Olap.Api.HierarchyController.index(conn))
  get("/hierarchies/:name", do: Olap.Api.HierarchyController.show(conn))

  match(_, do: conn |> Olap.Api.Controller.json(404, %{error: "Not Found"}))

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    error =
      case Mix.env() do
        :prod -> "Internal Server Error"
        _ -> inspect(reason)
      end

    conn |> Olap.Api.Controller.json(500, %{error: error}) |> halt()
  end
end

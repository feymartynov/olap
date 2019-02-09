defmodule Olap.Api.Controller do
  import Plug.Conn

  def cast_params(conn, schema_fun, as: assign_name) do
    changeset = schema_fun.(conn["params"])

    if changeset.valid? do
      conn |> assign(assign_name, changeset)
    else
      errors = changeset |> Ecto.Changeset.traverse_errors(&to_string/1)
      conn |> json(422, %{errors: errors}) |> halt()
    end
  end

  def json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  defmacro __using__(_) do
    quote do
      use Params
      import Olap.Api.Controller
    end
  end
end

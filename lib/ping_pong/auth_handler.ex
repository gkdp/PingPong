defmodule PingPong.AuthErrorHandler do
  import Phoenix.Controller, only: [redirect: 2]

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> redirect(to: "/")
  end
end

defmodule PingPongWeb.PageController do
  use PingPongWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

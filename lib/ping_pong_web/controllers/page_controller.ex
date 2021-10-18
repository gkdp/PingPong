defmodule PingPongWeb.PageController do
  use PingPongWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: PingPongWeb.Router.Helpers.scoreboard_index_path(conn, :index))
  end
end

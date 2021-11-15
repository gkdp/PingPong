defmodule PingPongWeb.PageController do
  use PingPongWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: PingPongWeb.Router.Helpers.scoreboard_season_path(conn, :index))
  end
end

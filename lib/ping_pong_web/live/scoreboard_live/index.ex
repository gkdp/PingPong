defmodule PingPongWeb.ScoreboardLive.Index do
  use PingPongWeb, :live_view

  import Ecto.Query

  alias PingPong.Scoreboard

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :users, list_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Scoreboard")
    |> assign(:team, nil)
  end

  defp list_users do
    Scoreboard.list_users()
  end
end

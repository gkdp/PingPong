defmodule PingPongWeb.LeagueLive.League do
  use PingPongWeb, :live_view

  import Ecto.Query, warn: false

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Leagues")}
  end
end

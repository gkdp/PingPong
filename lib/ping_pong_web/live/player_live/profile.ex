defmodule PingPongWeb.PlayerLive.Profile do
  use PingPongWeb, :live_view

  import Ecto.Query, warn: false

  alias PingPong.Scoreboard
  alias PingPong.Scoreboard.User

  @impl true
  def mount(_params, session, socket) do
    {user, claims} =
      with {:ok, user, claims} <- PingPong.Guardian.resource_from_token(session["guardian_default_token"]) do
        {user, claims}
      else
        _ -> {nil, nil}
      end

    {:ok,
    socket
    |> assign(
      user: PingPong.Repo.preload(user, :teams),
      changeset: User.changeset(user, %{}),
      claims: claims
    )}
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, User.get_slack_name(socket.assigns.user))
     |> assign(:teams, Scoreboard.get_teams())}
  end

  @impl true
  def handle_event("validate", %{"user" => user}, socket) do
    changeset =
      User.changeset(socket.assigns.user, user)

    PingPong.Repo.update!(changeset)

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
  end
end

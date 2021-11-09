defmodule PingPongWeb.ScoreboardLive.Index do
  use PingPongWeb, :live_view

  alias PingPong.Scoreboard

  @impl true
  def mount(_params, _session, socket) do
    users = list_users()

    {:ok,
     assign(socket,
       users_all: users,
       users: hide_users(users),
       changeset: changeset(),
       win_rate_left: nil,
       win_rate_right: nil,
       win_rate: nil,
       changeset_scores: changeset_scores(%{hide: true}),
       lowest_elo: Enum.min_by(users, & &1.elo, fn -> %{elo: 1000} end).elo
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"vs" => vs}, socket) do
    changeset = changeset(vs)

    with %{left_id: left_id, right_id: right_id}
          when not is_nil(left_id) and not is_nil(right_id) <-
            Ecto.Changeset.apply_changes(changeset) do
      left = Enum.find(socket.assigns.users, &(&1.id == String.to_integer(left_id)))
      right = Enum.find(socket.assigns.users, &(&1.id == String.to_integer(right_id)))

      win_rate =
        (Elo.expected_result(left.elo, right.elo) * 100)
        |> Float.ceil(2)

      {:noreply,
        socket
        |> assign(:win_rate_left, left)
        |> assign(:win_rate_right, right)
        |> assign(:win_rate, win_rate)
        |> assign(:changeset, changeset)}
    else
      _ ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_event("validate_scores", %{"scores" => scores}, socket) do
    changeset = changeset_scores(scores)

    users =
      if Ecto.Changeset.get_field(changeset, :hide) do
        hide_users(socket.assigns.users_all)
      else
        socket.assigns.users_all
      end

    {:noreply,
     socket
     |> assign(:users, users)
     |> assign(:changeset_scores, changeset)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Scoreboard")
    |> assign(:team, nil)
  end

  defp list_users do
    Scoreboard.list_users()
  end

  defp hide_users(users) do
    Enum.filter(users, fn user ->
      !Enum.empty?(user.winnings) || !Enum.empty?(user.losses)
    end)
  end

  @types %{left_id: :string, right_id: :string}
  defp changeset(params \\ %{}) do
    {%{}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
  end

  @types_scores %{hide: :boolean}
  defp changeset_scores(params) do
    {%{}, @types_scores}
    |> Ecto.Changeset.cast(params, Map.keys(@types_scores))
  end
end

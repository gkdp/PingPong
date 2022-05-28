defmodule PingPongWeb.ScoreboardLive.Index do
  use PingPongWeb, :live_view

  alias PingPong.Users

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    users =
      Users.get_users()

    changeset =
      changeset(%{
        hide_teams: false,
        team:
          case Map.get(params, "team") do
            nil -> nil
            id -> String.to_integer(id)
          end
      })

    {:noreply,
     socket
     |> assign(:page_title, "Tafeltennis")
     |> assign(:teams, list_teams(users))
    #  |> assign(:lowest_elo, lowest_elo(season))
     |> assign_changeset(users, changeset)}
  end

  @impl true
  def handle_event("validate", %{"filters" => filters}, socket) do
    changeset = changeset(filters)

    {:noreply,
     socket
     |> assign_changeset(socket.assigns.season, changeset)}
  end

  def format_team_names(teams) do
    total_teams = Enum.count(teams)

    for {team, index} <- Enum.with_index(teams, 1), reduce: "" do
      acc ->
        case index do
          x when x == total_teams ->
            acc <> get_team_name_span(team.name)

          x when x == total_teams - 1 ->
            acc <> get_team_name_span(team.name) <> " en "

          _ ->
            acc <> get_team_name_span(team.name) <> ", "
        end
    end
  end

  defp get_team_name_span(name) do
    "<span class=\"font-semibold\">Team " <> name <> "</span>"
  end

  defp list_teams(users) do
    users
    |> Enum.flat_map(& &1.teams)
    |> Enum.uniq_by(& &1.id)
  end

  defp assign_changeset(socket, users, changeset) do
    users =
      users
      |> then(fn users ->
        users
        |> Enum.filter(&(&1.count_won > 0 || &1.count_lost > 0))
      end)
      |> then(fn users ->
        with team when is_integer(team) <- Ecto.Changeset.get_field(changeset, :team) do
          users
          |> Enum.filter(fn user ->
            found = Enum.find(user.user.teams, &(&1.id == team))

            found != nil
          end)
        else
          _ -> users
        end
      end)

    socket
    |> assign(:changeset, changeset)
    |> assign(:hide_teams, Ecto.Changeset.get_field(changeset, :hide_teams))
    |> assign(:users, users)
  end

  @types %{hide_teams: :boolean, team: :integer}
  defp changeset(params) do
    {%{}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
  end
end

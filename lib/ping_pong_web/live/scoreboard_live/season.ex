defmodule PingPongWeb.ScoreboardLive.Season do
  use PingPongWeb, :live_view

  alias PingPong.Seasons
  alias PingPong.Seasons.Season

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    season =
      if(Map.has_key?(params, "id"),
        do: Seasons.get_season!(params["id"]),
        else: Seasons.get_active_season!()
      )
      |> Seasons.load_users()
      |> Seasons.load_user_scores()

    # with user <- Enum.find(season.season_users, &(&1.id == 13)) do
    #   IO.inspect user
    # end

    changeset =
      changeset(%{
        hide_players: true,
        hide_teams: false
      })

    {:noreply,
     socket
     |> assign(:page_title, season.title)
     |> assign(:season, season)
     |> assign(:teams, list_teams(season))
     |> assign(:lowest_elo, lowest_elo(season))
     |> assign_changeset(season, changeset)}
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

  defp list_teams(%Season{} = season) do
    season.users
    |> Enum.flat_map(& &1.teams)
    |> Enum.uniq_by(& &1.id)
  end

  defp lowest_elo(%Season{} = season) do
    season.season_users
    |> Enum.map(& &1.elo)
    |> Enum.min(fn -> 1000 end)
  end

  defp assign_changeset(socket, season, changeset) do
    users =
      season.season_users
      |> then(fn users ->
        if Ecto.Changeset.get_field(changeset, :hide_players) do
          users
          |> Enum.filter(&(&1.count_won > 0 || &1.count_lost > 0))
        else
          users
        end
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

  @types %{hide_players: :boolean, hide_teams: :boolean, team: :integer}
  defp changeset(params) do
    {%{}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
  end
end

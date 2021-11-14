defmodule PingPongWeb.ScoreboardLive.Season do
  use PingPongWeb, :live_view

  alias PingPong.Seasons
  alias PingPong.Seasons.Season

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _, socket) do
    season =
      Seasons.get_active_season!()
      |> Seasons.load_users()

    {:noreply,
     socket
     |> assign(:page_title, season.title)
     |> assign(:changeset, changeset(%{hide: true}))
     |> assign(:season, season)
     |> assign(:teams, list_teams(season))
     |> assign(:lowest_elo, lowest_elo(season))}
  end

  @impl true
  def handle_event("validate", %{"scores" => scores}, socket) do
    changeset = changeset(scores)

    {:noreply,
     socket
     |> assign(:changeset, changeset)}
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
    |> Enum.flat_map(&(&1.teams))
    |> Enum.uniq_by(&(&1.id))
  end

  defp lowest_elo(%Season{} = season) do
    season.season_users
    |> Enum.map(&(&1.elo))
    |> Enum.min(fn -> 1000 end)
  end

  @types %{hide: :boolean}
  defp changeset(params) do
    {%{}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
  end
end

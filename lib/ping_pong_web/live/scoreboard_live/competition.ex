defmodule PingPongWeb.ScoreboardLive.Competition do
  use PingPongWeb, :live_view

  alias PingPong.Competitions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    competition = Competitions.get_competition!(id)
    users = list_users(competition.id)

    {:noreply,
     socket
     |> assign(:page_title, competition.title)
     |> assign(:users, users)
     |> assign(:teams, Enum.uniq_by(Enum.flat_map(users, & &1.teams), & &1.id))
     |> assign(:lowest_elo, Enum.min_by(users, & &1.elo, fn -> %{elo: 1000} end).elo)
     |> assign(:competition, competition)}
  end

  def format_team_names(teams) do
    total_teams = Enum.count(teams)

    formatted =
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

    Phoenix.HTML.raw(formatted)
  end

  defp get_team_name_span(name) do
    "<span class=\"font-semibold\">Team " <> name <> "</span>"
  end

  defp list_users(id) do
    Competitions.list_competition_users(id)
    |> PingPong.Repo.preload(:teams)
    |> Enum.map(fn user ->
      %{user | elo: Map.get(List.first(user.user_competitions), :elo)}
    end)
  end
end

defmodule PingPongWeb.PlayerLive.Player do
  use PingPongWeb, :live_view

  import Ecto.Query, warn: false

  alias PingPong.Repo
  alias PingPong.Scoreboard
  alias PingPong.Scoreboard.User
  alias PingPong.Scores.Score

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    user =
      Scoreboard.get_user(id)
      |> Scoreboard.load_seasons_and_scores()
      |> PingPong.Repo.preload(:teams)

    {:noreply,
     socket
     |> assign(:page_title, User.get_slack_name(user))
     |> assign(:teams, Scoreboard.get_teams())
     |> assign(:is_admin, Map.get(params, "admin") == "abba")
     |> assign(:user, user)}
  end

  defp in_team(user, team) do
    item =
      Enum.find(user.teams, fn %{id: id} ->
        id == team.id
      end)

    case item do
      %{} -> true
      _ -> false
    end
  end

  defp other_players_per_season(season_users) do
    season_users = Enum.sort_by(season_users, & &1.season.start_at, {:desc, NaiveDateTime})

    for season_user <- season_users do
      scores =
        for score <- Enum.sort_by(season_user.scores, & &1.inserted_at, {:desc, NaiveDateTime}) do
          users =
            for %{season_user_id: id, season_user: other_user} when id != season_user.id <-
                  score.score_users do
              other_user
            end

          {score, users}
        end

      {season_user, scores}
    end
  end

  defp total(season_user, scores) do
    {won, lost} =
      for score <- scores, reduce: {0, 0} do
        {won, lost} ->
          side = Score.get_side(score, season_user)

          case score.winner == side do
            true ->
              {won + 1, lost}

            false ->
              {won, lost + 1}
          end
      end

    [won, lost]
  end

  defp get_values(season_user) do
    history =
      if length(season_user.elo_history) < 10 do
        [%{elo: 1000, inserted_at: season_user.inserted_at}] ++ season_user.elo_history
      else
        season_user.elo_history
      end

    lowest_elo =
      season_user.elo_history
      |> Enum.map(& &1.elo)
      |> Enum.min()

    values =
      for %{elo: elo, inserted_at: date} <- history do
        "{date: \"#{date}\", original: #{elo}, value: #{elo - lowest_elo}}"
      end

    Enum.join(values, ",")
  end

  @impl true
  def handle_event("save", params, socket) do
    list = Map.get(params, "team_id", [])
    team_users =
      from(u in PingPong.Teams.TeamUser,
        where: u.user_id == ^socket.assigns.user.id
      )
      |> Repo.all()

    list = Enum.map(list, & String.to_integer(&1))
    team_users_list = Enum.map(team_users, & &1.team_id)

    to_delete = Enum.filter(team_users, & &1.team_id not in list)
    to_add = Enum.filter(list, & &1 not in team_users_list)

    for team_user <- to_delete do
      Repo.delete!(team_user)
    end

    for id <- to_add do
      Repo.insert!(PingPong.Teams.TeamUser.changeset(%PingPong.Teams.TeamUser{}, %{
        team_id: id,
        user_id: socket.assigns.user.id
      }))
    end

    {:noreply, socket}
  end
end

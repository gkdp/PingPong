defmodule PingPongWeb.PlayerLive.Player do
  use PingPongWeb, :live_view

  alias PingPong.Scoreboard
  alias PingPong.Scoreboard.User
  alias PingPong.Scores.Score

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    user =
      Scoreboard.get_user(id)
      |> Scoreboard.load_seasons_and_scores()

    {won, lost} = total(user.season_users)

    {:noreply,
     socket
     |> assign(:page_title, User.get_slack_name(user))
     |> assign(:lowest_elo, lowest_elo(user.season_users))
     |> assign(:user, user)
     |> assign(:total, [won, lost])}
  end

  defp other_players_per_season(season_users) do
    for season_user <- season_users do
      scores =
        for score <- season_user.scores do
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

  defp total(season_users) do
    for season_user <- season_users, score <- season_user.scores, reduce: {0, 0} do
      {won, lost} ->
        side = Score.get_side(score, season_user)

        if score.winner == side do
          {won + 1, lost}
        else
          {won, lost + 1}
        end
    end
  end

  defp lowest_elo(season_users) do
    season_users
    |> Enum.map(& &1.elo)
    |> Enum.min(fn -> 1000 end)
  end

  defp get_values(season_user, lowest_elo) do
    history =
      if length(season_user.elo_history) < 10 do
        [%{elo: 1000, inserted_at: season_user.inserted_at}] ++ season_user.elo_history
      else
        season_user.elo_history
      end

    values =
      for %{elo: elo, inserted_at: date} <- history do
        "{date: \"#{date}\", original: #{elo}, value: #{elo - lowest_elo}}"
      end

    Enum.join(values, ",")
  end
end

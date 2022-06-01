defmodule Mix.Tasks.Elo.Recalculate do
  use Mix.Task

  import Ecto.Query, warn: false
  alias PingPong.Repo

  @requirements ["app.config", "app.start"]

  @shortdoc "Recalculate Elo"

  @moduledoc """
  This tasks recalculates the elo of all users.
  """

  @impl Mix.Task
  def run(_args) do
    users =
      from(u in PingPong.Scoreboard.User)
      |> Repo.all()

    history =
      from(e in PingPong.Scores.Score,
        where: not is_nil(e.confirmed_at),
        order_by: e.confirmed_at
      )
      |> Repo.all()
      |> Repo.preload([:users, :elo_history])

    calculated =
      for %{winner: winner, score_users: score_users, elo_history: elo_history}
          when length(score_users) == 2 <- history,
          %{side: ^winner} = winner_user <- score_users,
          %{side: side} = loser_user when side != winner <- score_users,
          reduce: Map.new(users, fn %{id: id} -> {id, 1000} end) do
        acc ->
          {winning_elo, losing_elo} =
            Elo.rate(
              Map.get(acc, winner_user.season_user.user_id),
              Map.get(acc, loser_user.season_user.user_id),
              :win,
              round: true,
              k_factor: 45
            )

          acc
          |> Map.update!(winner_user.season_user.user_id, fn _ ->
            found =
              elo_history
              |> Enum.find(&(&1.season_user_id == winner_user.season_user_id))

            if !is_nil(found) do
              found
              |> Ecto.Changeset.change(%{elo_user: winning_elo})
              |> Repo.update!()
            end

            winning_elo
          end)
          |> Map.update!(loser_user.season_user.user_id, fn _ ->
            found =
              elo_history
              |> Enum.find(&(&1.season_user_id == loser_user.season_user_id))

            if !is_nil(found) do
              found
              |> Ecto.Changeset.change(%{elo_user: losing_elo})
              |> Repo.update!()
            end

            losing_elo
          end)
      end

    for user <- users do
      user
      |> Ecto.Changeset.change(%{elo: Map.get(calculated, user.id)})
      |> Repo.update!()
    end

    Mix.shell().info("Success!")
  end
end

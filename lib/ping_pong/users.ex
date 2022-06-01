defmodule PingPong.Users do
  @moduledoc """
  The Scoreboard context.
  """

  require Logger

  import Ecto.Query, warn: false
  alias PingPong.Repo

  alias PingPong.Scoreboard.User
  alias PingPong.Scores.ScoreUser
  alias PingPong.Scores.Elo

  def get_user(id) do
    Repo.get!(User, id)
  end

  def get_users() do
    users =
      Repo.all(
        from s in User,
          order_by: [desc: s.elo]
      )
      |> Repo.preload([:teams, elo_history: from(c in Elo, order_by: c.inserted_at)])

    score_users =
      Repo.all(
        from c in ScoreUser,
          join: s in assoc(c, :score),
          join: u in assoc(c, :season_user),
          where:
            not is_nil(s.confirmed_at) and is_nil(s.denied_at) and
              u.user_id in ^Enum.map(users, & &1.id),
          group_by: u.user_id,
          select: %{
            id: u.user_id,
            won: sum(fragment("case when ? = ? then 1 else 0 end", c.side, s.winner)),
            lost: sum(fragment("case when ? != ? then 1 else 0 end", c.side, s.winner))
          }
      )

    for %{id: id} = user <- users do
      with %{won: won, lost: lost} <- Enum.find(score_users, &(&1.id == id)) do
        %{user | count_won: won, count_lost: lost}
      else
        _ ->
          %{user | count_won: 0, count_lost: 0}
      end
    end
  end

  def get_teams() do
    Repo.all(PingPong.Teams.Team)
  end
end

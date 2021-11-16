defmodule PingPong.Seasons do
  @moduledoc """
  The Seasons context.
  """

  import Ecto.Query, warn: false
  alias PingPong.Repo

  alias PingPong.Seasons.Season
  alias PingPong.Seasons.SeasonUser
  alias PingPong.Scores.Score
  alias PingPong.Scores.ScoreUser
  alias PingPong.Scores.Elo

  @doc """
  Returns the list of seasons.

  ## Examples

      iex> list_seasons()
      [%Season{}, ...]

  """
  def list_seasons do
    Repo.all(Season)
  end

  @doc """
  Gets a single season.

  Raises `Ecto.NoResultsError` if the Season does not exist.

  ## Examples

      iex> get_season!(123)
      %season{}

      iex> get_season!(456)
      ** (Ecto.NoResultsError)

  """
  def get_season!(id), do: Repo.get!(Season, id)

  @doc """
  Gets a single season that is currently active.

  Raises `Ecto.NoResultsError` if no season can be found or there are more
  seasons active.

  ## Examples

      iex> get_active_season!()
      %season{}

      iex> get_active_season!()
      ** (Ecto.NoResultsError)

  """
  def get_active_season!() do
    from(s in Season,
      where:
        s.start_at <= ^NaiveDateTime.utc_now() and
          (s.end_at >= ^NaiveDateTime.utc_now() or is_nil(s.end_at))
    )
    |> Repo.one!()
  end

  def get_active_season() do
    from(s in Season,
      where:
        s.start_at <= ^NaiveDateTime.utc_now() and
          (s.end_at >= ^NaiveDateTime.utc_now() or is_nil(s.end_at))
    )
    |> Repo.one()
  end

  def load_users(%Season{} = season) do
    elo_history_partition_query =
      from c in Elo,
        select: %{id: c.id, row_number: over(row_number(), :users_partition)},
        windows: [
          users_partition: [partition_by: :season_user_id, order_by: [desc: :inserted_at]]
        ]

    elo_history =
      from c in Elo,
        join: r in subquery(elo_history_partition_query),
        on: c.id == r.id and r.row_number <= 10,
        order_by: :inserted_at

    season_users =
      from s in SeasonUser,
        order_by: [desc: s.elo]

    season =
      season
      |> Repo.preload(
        season_users: {season_users, [elo_history: elo_history]},
        users: [:teams]
      )

    score_users =
      Repo.all(
        from c in ScoreUser,
          join: s in assoc(c, :score),
          where:
            (not is_nil(s.confirmed_at) and is_nil(s.denied_at)) and
              c.season_user_id in ^Enum.map(season.season_users, & &1.id),
          group_by: c.season_user_id,
          select: %{
            id: c.season_user_id,
            won: sum(fragment("case when ? = ? then 1 else 0 end", c.side, s.winner)),
            lost: sum(fragment("case when ? != ? then 1 else 0 end", c.side, s.winner))
          }
      )

    season
    |> Map.update!(:season_users, fn season_users ->
      for %{id: id} = season_user <- season_users do
        with %{won: won, lost: lost} <- Enum.find(score_users, &(&1.id == id)) do
          %{season_user | count_won: won, count_lost: lost}
        else
          _ ->
            %{season_user | count_won: 0, count_lost: 0}
        end
      end
    end)
  end

  def load_user_scores(%Season{} = season) do
    scores =
      Repo.all(
        from c in Score,
          join: s in assoc(c, :score_users),
          join: su in assoc(s, :season_user),
          join: u in assoc(su, :user),
          preload: [score_users: {s, [season_user: {su, [user: u]}]}],
          order_by: [desc: c.confirmed_at],
          where:
            (not is_nil(c.confirmed_at) and is_nil(c.denied_at)) and
              s.season_user_id in ^Enum.map(season.season_users, & &1.id)
      )

    season
    |> Map.update!(:season_users, fn season_users ->
      for %{id: id} = season_user <- season_users do
        scores =
          Enum.filter(scores, fn %{score_users: users} ->
            Enum.find(users, &(&1.season_user_id == id))
          end)

        %{season_user | scores: scores}
      end
    end)
  end
end

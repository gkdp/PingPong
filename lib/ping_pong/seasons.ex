defmodule PingPong.Seasons do
  @moduledoc """
  The Seasons context.
  """

  import Ecto.Query, warn: false
  alias PingPong.Repo

  alias PingPong.Seasons.Season
  alias PingPong.Seasons.SeasonUser
  alias PingPong.Scores.ScoreView
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

    winnings = from(c in ScoreView, where: not is_nil(c.confirmed_at))

    losses = from(c in ScoreView, where: not is_nil(c.confirmed_at))

    season_users =
      from(s in SeasonUser,
        order_by: [desc: s.elo]
      )

    season
    |> Repo.preload(
      season_users: {season_users, [elo_history: elo_history, winnings: winnings, losses: losses]},
      users: [:teams]
    )
  end

  # def list_season_users(id) do
  #   ranking_query =
  #     from c in EloHistory,
  #       select: %{id: c.id, row_number: over(row_number(), :users_partition)},
  #       windows: [users_partition: [partition_by: :user_id, order_by: [desc: :inserted_at]]]

  #   history_query =
  #     from c in EloHistory,
  #       join: r in subquery(ranking_query),
  #       on: c.id == r.id and r.row_number <= 10,
  #       where: c.season_id == ^id,
  #       order_by: :inserted_at

  #   from(u in User,
  #     # as: :user,
  #     join: c in SeasonUser,
  #     on: c.user_id == u.id,
  #     where: c.season_id == ^id,
  #     # where:
  #     #   exists(
  #     #     from(
  #     #       c in "season_user",
  #     #       where: c.season_id == ^id and c.user_id == parent_as(:user).id,
  #     #       select: 1
  #     #     )
  #     #   ),
  #     order_by: [desc: u.elo],
  #     preload: [user_seasons: c]
  #   )
  #   |> Repo.all()
  #   |> Repo.preload(
  #     winnings: from(c in ScoreWinner, where: not is_nil(c.confirmed_at) and c.season_id == ^id),
  #     losses: from(c in ScoreWinner, where: not is_nil(c.confirmed_at) and c.season_id == ^id),
  #     # user_seasons: from(c in seasonUser, where: c.season_id == ^id),
  #     elo_history: history_query
  #   )
  # end

  # @doc """
  # Creates a season.

  # ## Examples

  #     iex> create_season(%{field: value})
  #     {:ok, %Season{}}

  #     iex> create_season(%{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def create_season(attrs \\ %{}) do
  #   %Season{}
  #   |> Season.changeset(attrs)
  #   |> Repo.insert()
  # end

  # @doc """
  # Updates a season.

  # ## Examples

  #     iex> update_season(season, %{field: new_value})
  #     {:ok, %Season{}}

  #     iex> update_season(season, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_season(%Season{} = season, attrs) do
  #   season
  #   |> Season.changeset(attrs)
  #   |> Repo.update()
  # end

  # @doc """
  # Deletes a season.

  # ## Examples

  #     iex> delete_season(season)
  #     {:ok, %Season{}}

  #     iex> delete_season(season)
  #     {:error, %Ecto.Changeset{}}

  # """
  # def delete_season(%Season{} = season) do
  #   Repo.delete(season)
  # end

  # @doc """
  # Returns an `%Ecto.Changeset{}` for tracking season changes.

  # ## Examples

  #     iex> change_season(season)
  #     %Ecto.Changeset{data: %Season{}}

  # """
  # def change_season(%Season{} = season, attrs \\ %{}) do
  #   Season.changeset(season, attrs)
  # end
end

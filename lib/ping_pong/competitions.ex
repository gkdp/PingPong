defmodule PingPong.Competitions do
  @moduledoc """
  The Competitions context.
  """

  import Ecto.Query, warn: false
  alias PingPong.Repo

  alias PingPong.Competitions.Competition
  alias PingPong.Competitions.CompetitionUser
  alias PingPong.Scoreboard.User
  alias PingPong.Scoreboard.ScoreWinner
  alias PingPong.Scoreboard.EloHistory

  @doc """
  Returns the list of competitions.

  ## Examples

      iex> list_competitions()
      [%Competition{}, ...]

  """
  def list_competitions do
    Repo.all(Competition)
  end

  @doc """
  Gets a single competition.

  Raises `Ecto.NoResultsError` if the Competition does not exist.

  ## Examples

      iex> get_competition!(123)
      %Competition{}

      iex> get_competition!(456)
      ** (Ecto.NoResultsError)

  """
  def get_competition!(id), do: Repo.get!(Competition, id)

  def list_competition_users(id) do
    ranking_query =
      from c in EloHistory,
        select: %{id: c.id, row_number: over(row_number(), :users_partition)},
        windows: [users_partition: [partition_by: :user_id, order_by: [desc: :inserted_at]]]

    history_query =
      from c in EloHistory,
        join: r in subquery(ranking_query),
        on: c.id == r.id and r.row_number <= 10,
        where: c.competition_id == ^id,
        order_by: :inserted_at

    from(u in User,
      # as: :user,
      join: c in CompetitionUser, on: c.user_id == u.id,
      where: c.competition_id == ^id,
      # where:
      #   exists(
      #     from(
      #       c in "competition_user",
      #       where: c.competition_id == ^id and c.user_id == parent_as(:user).id,
      #       select: 1
      #     )
      #   ),
      order_by: [desc: u.elo],
      preload: [user_competitions: c]
    )
    |> Repo.all()
    |> Repo.preload(
      winnings: from(c in ScoreWinner, where: not is_nil(c.confirmed_at) and c.competition_id == ^id),
      losses: from(c in ScoreWinner, where: not is_nil(c.confirmed_at) and c.competition_id == ^id),
      # user_competitions: from(c in CompetitionUser, where: c.competition_id == ^id),
      elo_history: history_query
    )
  end

  @doc """
  Creates a competition.

  ## Examples

      iex> create_competition(%{field: value})
      {:ok, %Competition{}}

      iex> create_competition(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_competition(attrs \\ %{}) do
    %Competition{}
    |> Competition.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a competition.

  ## Examples

      iex> update_competition(competition, %{field: new_value})
      {:ok, %Competition{}}

      iex> update_competition(competition, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_competition(%Competition{} = competition, attrs) do
    competition
    |> Competition.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a competition.

  ## Examples

      iex> delete_competition(competition)
      {:ok, %Competition{}}

      iex> delete_competition(competition)
      {:error, %Ecto.Changeset{}}

  """
  def delete_competition(%Competition{} = competition) do
    Repo.delete(competition)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking competition changes.

  ## Examples

      iex> change_competition(competition)
      %Ecto.Changeset{data: %Competition{}}

  """
  def change_competition(%Competition{} = competition, attrs \\ %{}) do
    Competition.changeset(competition, attrs)
  end
end

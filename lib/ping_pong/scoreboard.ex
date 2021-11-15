defmodule PingPong.Scoreboard do
  @moduledoc """
  The Scoreboard context.
  """

  require Logger

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [change: 2]
  alias PingPong.Repo

  alias PingPong.Commands.Report
  alias PingPong.Scoreboard.User
  alias PingPong.Seasons.SeasonUser
  alias PingPong.Scores.Score
  alias PingPong.Scores.ScoreView
  alias PingPong.Scores.Elo, as: EloHistory
  alias PingPong.Seasons
  alias Slack.Web.Users
  alias PingPong.Slack

  # def list_users do
  #   ranking_query =
  #     from c in EloHistory,
  #       select: %{id: c.id, row_number: over(row_number(), :users_partition)},
  #       windows: [users_partition: [partition_by: :user_id, order_by: [desc: :inserted_at]]]

  #   history_query =
  #     from c in EloHistory,
  #       join: r in subquery(ranking_query),
  #       on: c.id == r.id and r.row_number <= 10,
  #       order_by: :inserted_at

  #   from(u in User,
  #     order_by: [desc: u.elo]
  #   )
  #   |> Repo.all()
  #   |> Repo.preload(
  #     winnings:
  #       from(c in ScoreWinner, where: not is_nil(c.confirmed_at) and is_nil(c.season_id)),
  #     losses:
  #       from(c in ScoreWinner, where: not is_nil(c.confirmed_at) and is_nil(c.season_id)),
  #     elo_history: history_query
  #   )
  # end

  @doc """
  Gets a single score.

  Raises `Ecto.NoResultsError` if the Score does not exist.

  ## Examples

      iex> get_score!(123)
      %Score{}

      iex> get_score!(456)
      ** (Ecto.NoResultsError)

  """
  def get_score!(id) do
    Repo.get!(Score, id)
    |> Repo.preload([left: [:user], right: [:user]])
  end

  def get_user_by_slack(id) when is_binary(id) do
    Repo.get_by(User, slack_id: id)
  end

  def get_or_create_user_by_slack(id) when is_binary(id) do
    with nil <- get_user_by_slack(id),
         %{"ok" => true, "user" => info} <- Users.info(id),
         false <- Map.get(info, "is_bot") do
      user =
        %User{
          slack_id: id
        }
        |> Repo.insert!()
        |> Map.put(:winnings, [])

      {:ok, user}
    else
      %User{} = user -> {:ok, user}
      _ -> {:error, nil}
    end
  end

  def get_or_create_season_user_for_user(%User{} = user, season_id) do
    user =
      user
      |> Repo.preload(season_user: from(u in SeasonUser, where: u.season_id == ^season_id))

    if is_nil(user.season_user) do
      season_user =
        %SeasonUser{
          user_id: user.id,
          season_id: season_id
        }
        |> Repo.insert!()

      %{user | season_user: season_user}
    else
      user
    end
  end

  # def process_scores(%Report{left_id: left_id, right_id: right_id})
  #     when left_id == right_id do
  #   {:error, :equals}
  # end

  def process_scores(%Report{} = report) do
    with {:ok, left} <- get_or_create_user_by_slack(report.left_id),
         {:ok, right} <- get_or_create_user_by_slack(report.right_id),
         %Seasons.Season{} = season <- Seasons.get_active_season() do
      processed =
        for %Report.Score{} = score <- report.scores do
          left = get_or_create_season_user_for_user(left, season.id)
          right = get_or_create_season_user_for_user(right, season.id)

          # Session ding
          with {:ok, final} <- process_score(left, right, score) do
            final
          else
            _ -> nil
          end
        end

      {:ok, Enum.filter(processed, &(!is_nil(&1)))}
    else
      nil -> {:error, :season_not_found}
      _ -> {:error, nil}
    end
  end

  defp process_score(left, right, %Report.Score{} = score) do
    winner =
      cond do
        score.left > score.right -> :left
        score.left < score.right -> :right
        true -> :draw
      end

    inserted_score =
      Repo.insert(
        Score.changeset(%Score{}, %{
          left_id: left.season_user.id,
          right_id: right.season_user.id,
          winner: winner,
          left_score: score.left,
          right_score: score.right
        })
      )

    {winning_user, winning_score} =
      if(winner == :left, do: {left, score.left}, else: {right, score.right})

    {losing_user, losing_score} =
      if(winner != :left, do: {left, score.left}, else: {right, score.right})

    with {:ok, final_score} = tuple <- inserted_score do
      Slack.send_confirm_message(
        {winning_user, winning_score},
        {losing_user, losing_score},
        right,
        final_score
      )

      tuple
    end
  end

  def confirm_score(%Score{winner: winner} = score) do
    winning_user = if(winner == :left, do: score.left, else: score.right)
    losing_user = if(winner != :left, do: score.left, else: score.right)

    wins =
      Repo.aggregate(
        from(s in ScoreView,
          where: not is_nil(s.confirmed_at) and s.won_by_id == ^winning_user.id
        ),
        :count
      )

    {winning_elo, losing_elo} =
      Elo.rate(
        winning_user.elo,
        losing_user.elo,
        :win,
        round: true,
        k_factor: get_k_factor(wins, winning_user.elo)
      )

    time = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    Repo.transaction(fn ->
      Repo.update!(change(winning_user, elo: winning_elo))
      Repo.update!(change(losing_user, elo: losing_elo))

      Repo.insert!(
        change(%EloHistory{}, %{
          season_user_id: winning_user.id,
          score_id: score.id,
          elo: winning_elo
        })
      )

      Repo.insert!(
        change(%EloHistory{}, %{
          season_user_id: losing_user.id,
          score_id: score.id,
          elo: losing_elo
        })
      )

      Repo.update!(change(score, confirmed_at: time))
    end)

    %Score{score | confirmed_at: time}
  end

  def deny_score(%Score{} = score) do
    Repo.update!(
      change(score, denied_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second))
    )
  end

  def scheduled_confirm do
    scores =
      from(s in Score,
        where: s.inserted_at <= ago(1, "day") and is_nil(s.confirmed_at) and is_nil(s.denied_at)
      )
      |> Repo.all()
      |> Repo.preload([:left, :right])

    for score <- scores do
      Logger.info("Auto confirm score", score_id: score.id)

      Slack.send_confirmation_message(confirm_score(score))
    end
  end

  defp get_k_factor(wins, elo) do
    cond do
      wins <= 10 -> 60
      elo >= 2000 -> 10
      true -> 25
    end
  end
end

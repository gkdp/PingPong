defmodule PingPong.Scoreboard do
  @moduledoc """
  The Scoreboard context.
  """

  require Logger

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [change: 2]
  alias PingPong.Repo

  alias PingPong.Commands.Report
  alias PingPong.Commands.DoublesReport
  alias PingPong.Scoreboard.User
  alias PingPong.Seasons.Season
  alias PingPong.Seasons.SeasonUser
  alias PingPong.Scores.Score
  alias PingPong.Scores.ScoreUser
  alias PingPong.Scores.Elo, as: EloHistory
  alias PingPong.Seasons
  alias Slack.Web.Users
  alias PingPong.Slack

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
    |> Repo.preload([:users])
  end

  def get_user(id) do
    Repo.get!(User, id)
  end

  def get_teams() do
    Repo.all(PingPong.Teams.Team)
  end

  def load_seasons(%User{} = user) do
    user
    |> Repo.preload(:season_users)
  end

  def load_seasons_and_scores(%User{} = user) do
    elo_history_partition_query =
      from c in PingPong.Scores.Elo,
        select: %{id: c.id, row_number: over(row_number(), :users_partition)},
        windows: [
          users_partition: [partition_by: :season_user_id, order_by: [desc: :inserted_at]]
        ]

    elo_history =
      from c in PingPong.Scores.Elo,
        join: r in subquery(elo_history_partition_query),
        on: c.id == r.id and r.row_number <= 10,
        order_by: :inserted_at

    user
    |> Repo.preload(
      season_users: [
        elo_history: elo_history,
        scores: {from(c in Score, where: not is_nil(c.confirmed_at)), [season_users: [:user]]},
        season: []
      ]
    )
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

  def set_or_create_season_user_for_user(%User{} = user, season_id) do
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

  def process_scores(%Report{left_id: left_id, right_id: right_id})
      when left_id == right_id do
    {:error, :equals}
  end

  def process_scores(%DoublesReport{
        left_id: left_id,
        left_buddy_id: left_buddy_id,
        right_id: right_id,
        right_buddy_id: right_buddy_id
      })
      when left_id == right_id or left_id == left_buddy_id or left_id == right_buddy_id or
             right_id == right_buddy_id or left_buddy_id == right_id or
             left_buddy_id == right_buddy_id do
    {:error, :equals}
  end

  def process_scores(%Report{} = report) do
    left = get_or_create_user_by_slack(report.left_id)
    right = get_or_create_user_by_slack(report.right_id)

    with %Season{id: season_id} <- Seasons.get_active_season(),
         {:ok, left} <- left,
         {:ok, right} <- right do
      left = set_or_create_season_user_for_user(left, season_id)
      right = set_or_create_season_user_for_user(right, season_id)

      # list =
      #   report.scores
      #   |> Enum.map(fn score ->
      #     cond do
      #       score.left > score.right -> :left
      #       score.left < score.right -> :right
      #       true -> :draw
      #     end
      #   end)

      # left_won = Enum.count(list, &(&1 == :left))
      # right_won = Enum.count(list, &(&1 == :right))
      # draw = left_won == right_won
      draw = false

      scores =
        report.scores
        |> Enum.map(fn score ->
          with {:ok, final} <- process_score(left, right, score, draw) do
            final
          else
            _ -> nil
          end
        end)
        |> Enum.filter(&(!is_nil(&1)))

      {:ok, scores}
    else
      nil -> {:error, :season_not_found}
      _ -> {:error, nil}
    end
  end

  def process_scores(%DoublesReport{} = report) do
    left = get_or_create_user_by_slack(report.left_id)
    left_buddy = get_or_create_user_by_slack(report.left_buddy_id)
    right = get_or_create_user_by_slack(report.right_id)
    right_buddy = get_or_create_user_by_slack(report.right_buddy_id)

    with %Season{id: season_id} <- Seasons.get_active_season(),
         {:ok, left} <- left,
         {:ok, left_buddy} <- left_buddy,
         {:ok, right} <- right,
         {:ok, right_buddy} <- right_buddy do
      left = set_or_create_season_user_for_user(left, season_id)
      left_buddy = set_or_create_season_user_for_user(left_buddy, season_id)
      right = set_or_create_season_user_for_user(right, season_id)
      right_buddy = set_or_create_season_user_for_user(right_buddy, season_id)

      scores =
        report.scores
        |> Enum.map(fn score ->
          with {:ok, final} <- process_score({left, left_buddy}, {right, right_buddy}, score) do
            final
          else
            _ -> nil
          end
        end)
        |> Enum.filter(&(!is_nil(&1)))

      {:ok, scores}
    else
      nil -> {:error, :season_not_found}
      _ -> {:error, nil}
    end
  end

  defp process_score({left, left_buddy}, {right, right_buddy}, %DoublesReport.Score{} = score) do
    winner =
      cond do
        score.left > score.right -> :left
        score.left < score.right -> :right
        true -> :draw
      end

    inserted_score =
      Repo.insert(
        Score.changeset(%Score{}, %{
          winner: winner,
          left_score: score.left,
          right_score: score.right
        })
        |> Ecto.Changeset.put_assoc(:score_users, [
          %ScoreUser{side: :left, season_user_id: left.season_user.id},
          %ScoreUser{side: :left, season_user_id: left_buddy.season_user.id},
          %ScoreUser{side: :right, season_user_id: right.season_user.id},
          %ScoreUser{side: :right, season_user_id: right_buddy.season_user.id}
        ])
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

  defp process_score(left, right, %Report.Score{} = score, draw \\ false) do
    winner =
      cond do
        score.left > score.right -> :left
        score.left < score.right -> :right
        true -> :draw
      end

    inserted_score =
      Repo.insert(
        Score.changeset(%Score{}, %{
          winner: winner,
          draw: draw,
          left_score: score.left,
          right_score: score.right
        })
        |> Ecto.Changeset.put_assoc(:score_users, [
          %ScoreUser{side: :left, season_user_id: left.season_user.id},
          %ScoreUser{side: :right, season_user_id: right.season_user.id}
        ])
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

  def confirm_score(%Score{} = score) do
    confirm_score(
      score,
      Score.get_winning_score_users(score),
      Score.get_losing_score_users(score)
    )
  end

  def confirm_score(%Score{} = score, [%ScoreUser{} = winner], [%ScoreUser{} = loser]) do
    wins =
      Repo.aggregate(
        from(s in Score,
          join: u in assoc(s, :score_users),
          where:
            not is_nil(s.confirmed_at) and
              u.season_user_id == ^winner.season_user_id and
              u.side == s.winner
        ),
        :count
      )

    {winning_elo, losing_elo} =
      Elo.rate(
        winner.season_user.elo,
        loser.season_user.elo,
        :win,
        round: true,
        k_factor: get_k_factor(wins, winner.season_user.elo)
      )

    winning_user = Enum.find(score.users, &(&1.id == winner.season_user.user_id))

    losing_user = Enum.find(score.users, &(&1.id == loser.season_user.user_id))

    {winning_elo_user, losing_elo_user} =
      Elo.rate(
        winning_user.elo,
        losing_user.elo,
        :win,
        round: true,
        k_factor: get_k_factor(wins, winner.season_user.user.elo)
      )

    Repo.transaction(fn ->
      Repo.update!(
        SeasonUser.changeset(winner.season_user, %{
          elo: winning_elo
        })
      )

      Repo.update!(
        SeasonUser.changeset(loser.season_user, %{
          elo: losing_elo
        })
      )

      Repo.update!(
        User.changeset(winning_user, %{
          elo: winning_elo_user
        })
      )

      Repo.update!(
        User.changeset(losing_user, %{
          elo: losing_elo_user
        })
      )

      Repo.insert!(
        EloHistory.changeset(%EloHistory{}, %{
          elo: winning_elo,
          elo_user: winning_elo_user,
          season_user_id: winner.season_user_id,
          score_id: score.id
        })
      )

      Repo.insert!(
        EloHistory.changeset(%EloHistory{}, %{
          elo: losing_elo,
          elo_user: losing_elo_user,
          season_user_id: loser.season_user_id,
          score_id: score.id
        })
      )

      Repo.update!(
        change(score, %{
          confirmed_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
        })
      )
    end)
  end

  def confirm_score(score, [_ | _] = winners, [_ | _] = losers) do
    winning_elo_sum =
      Enum.reduce(winners, 0, fn winner, acc ->
        acc + winner.season_user.elo
      end)

    losing_elo_sum =
      Enum.reduce(losers, 0, fn loser, acc ->
        acc + loser.season_user.elo
      end)

    {winning_elo, losing_elo} =
      Elo.rate(
        winning_elo_sum,
        losing_elo_sum,
        :win,
        round: true,
        k_factor: 45
      )

    rest_winning_elo = winning_elo - winning_elo_sum
    rest_losing_elo = losing_elo - losing_elo_sum

    Repo.transaction(fn ->
      for winner <- winners do
        elo = winner.season_user.elo + rest_winning_elo

        Repo.update!(
          SeasonUser.changeset(winner.season_user, %{
            elo: elo
          })
        )

        previous =
          Repo.one(
            from e in EloHistory,
              where: e.season_user_id == ^winner.season_user_id,
              order_by: [desc: e.id]
          )

        Repo.insert!(
          EloHistory.changeset(%EloHistory{}, %{
            elo: elo,
            elo_user: if(!is_nil(previous), do: previous.elo_user, else: 1000),
            season_user_id: winner.season_user_id,
            score_id: score.id
          })
        )
      end

      for loser <- losers do
        elo = loser.season_user.elo + rest_losing_elo

        Repo.update!(
          SeasonUser.changeset(loser.season_user, %{
            elo: elo
          })
        )

        previous =
          Repo.one(
            from e in EloHistory,
              where: e.season_user_id == ^loser.season_user_id,
              order_by: [desc: e.id]
          )

        Repo.insert!(
          EloHistory.changeset(%EloHistory{}, %{
            elo: elo,
            elo_user: if(!is_nil(previous), do: previous.elo_user, else: 1000),
            season_user_id: loser.season_user_id,
            score_id: score.id
          })
        )
      end

      Repo.update!(
        change(score, %{
          confirmed_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
        })
      )
    end)
  end

  def deny_score(%Score{} = score) do
    Repo.update!(
      change(score, %{
        denied_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
      })
    )
  end

  def scheduled_confirm do
    scores =
      from(s in Score,
        where: s.inserted_at <= ago(1, "day") and is_nil(s.confirmed_at) and is_nil(s.denied_at)
      )
      |> Repo.all()
      |> Repo.preload([:users])

    for score <- scores do
      right =
        Score.get_score_users(score, :right)
        |> Enum.map(& &1.season_user.user)
        |> List.first()

      Logger.info("Auto confirm score", score_id: score.id)

      {:ok, score} = confirm_score(score)

      Slack.send_confirmation_message(score, right.slack_id, true)
    end
  end

  defp get_k_factor(_wins, _elo) do
    # cond do
    #   wins <= 10 -> 60
    #   elo >= 2000 -> 10
    #   elo <= 950 -> 35
    #   true -> 25
    # end

    45
  end
end

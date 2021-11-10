defmodule PingPong.Scoreboard do
  @moduledoc """
  The Scoreboard context.
  """

  require Logger

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [change: 2]
  alias PingPong.Repo

  alias PingPong.Commands
  alias PingPong.Scoreboard.Score
  alias PingPong.Scoreboard.ScoreWinner
  alias PingPong.Scoreboard.EloHistory
  alias PingPong.Scoreboard.User
  alias Slack.Web.Chat

  @doc """
  Returns the list of scores.

  ## Examples

      iex> list_scores()
      [%Score{}, ...]

  """
  def list_scores do
    Repo.all(Score)
  end

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
    |> Repo.preload([:left, :right])
  end

  @doc """
  Creates a score.

  ## Examples

      iex> create_score(%{field: value})
      {:ok, %Score{}}

      iex> create_score(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_score(attrs \\ %{}) do
    %Score{}
    |> Score.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    ranking_query =
      from c in EloHistory,
      select: %{id: c.id, row_number: over(row_number(), :users_partition)},
      windows: [users_partition: [partition_by: :user_id, order_by: [desc: :inserted_at]]]

    history_query =
      from c in EloHistory,
      join: r in subquery(ranking_query),
      on: c.id == r.id and r.row_number <= 10,
      order_by: :inserted_at

    from(u in User,
      order_by: [desc: u.elo]
    )
    |> Repo.all()
    |> Repo.preload(
      winnings: from(c in ScoreWinner, where: not is_nil(c.confirmed_at)),
      losses: from(c in ScoreWinner, where: not is_nil(c.confirmed_at)),
      elo_history: history_query
    )
  end

  def get_user_by_slack(id) when is_binary(id) do
    Repo.get_by(User, slack_id: id)
  end

  def get_or_create_user_by_slack(id) when is_binary(id) do
    with nil <- get_user_by_slack(id),
         %{"ok" => true, "user" => info} <- Slack.Web.Users.info(id),
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

  def process_score(%Commands.Report{left_id: left_id, right_id: right_id})
      when left_id == right_id do
    {:error, :equals}
  end

  def process_score(%Commands.Report{} = report) do
    with {:ok, left} <- get_or_create_user_by_slack(report.left_id),
         {:ok, right} <- get_or_create_user_by_slack(report.right_id) do
      do_score(left, right, report)
    else
      _ -> {:error, nil}
    end
  end

  defp do_score(left, right, %Commands.Report{} = report) do
    winner =
      cond do
        report.left > report.right -> :left
        report.left < report.right -> :right
        true -> :draw
      end

    changeset =
      Score.changeset(%Score{}, %{
        left_id: left.id,
        right_id: right.id,
        winner: winner,
        left_score: report.left,
        right_score: report.right
      })

    score =
      changeset
      |> Repo.insert()

    {winning_user, winning_score} =
      if(winner == :left, do: {left, report.left}, else: {right, report.right})

    {losing_user, losing_score} =
      if(winner != :left, do: {left, report.left}, else: {right, report.right})

    with {:ok, score} = tuple <- score do
      send_confirm_message(
        {winning_user, winning_score},
        {losing_user, losing_score},
        right,
        score
      )

      tuple
    end
  end

  def confirm_score(%Score{winner: winner} = score) do
    winning_user = if(winner == :left, do: score.left, else: score.right)
    losing_user = if(winner != :left, do: score.left, else: score.right)

    wins =
      Repo.aggregate(
        from(s in ScoreWinner,
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
        change(%EloHistory{}, %{user_id: winning_user.id, score_id: score.id, elo: winning_elo})
      )

      Repo.insert!(
        change(%EloHistory{}, %{user_id: losing_user.id, score_id: score.id, elo: losing_elo})
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

  def send_confirm_message({winner, score_winner}, {loser, score_loser}, right, score) do
    message =
      if winner.id == right.id do
        "Volgens <@#{loser.slack_id}> heb je gewonnen met #{score_winner}:#{score_loser}. Bevestigen?"
      else
        "Volgens <@#{winner.slack_id}> heb je verloren met #{score_winner}:#{score_loser}. Bevestigen?"
      end

    Chat.post_message(
      right.slack_id,
      message,
      %{
        blocks:
          Jason.encode!([
            %{
              type: "section",
              text: %{
                type: "mrkdwn",
                text: message
              }
            },
            %{
              type: "actions",
              elements: [
                %{
                  type: "button",
                  text: %{
                    type: "plain_text",
                    text: "Bevestig"
                  },
                  style: "primary",
                  value: "confirm:#{score.id}"
                },
                %{
                  type: "button",
                  text: %{
                    type: "plain_text",
                    text: "Weiger"
                  },
                  style: "danger",
                  value: "deny:#{score.id}"
                }
              ]
            }
          ])
      }
    )
  end

  def send_confirmation_message(%Score{confirmed_at: time} = score) when not is_nil(time) do
    Chat.post_message(
      score.left.slack_id,
      "<@#{score.right.slack_id}> heeft de score #{score.left_score}:#{score.right_score} bevestigd."
    )
  end

  def send_confirmation_message(%Score{denied_at: time} = score) when not is_nil(time) do
    Chat.post_message(
      score.left.slack_id,
      "<@#{score.right.slack_id}> heeft de score #{score.left_score}:#{score.right_score} geweigerd."
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

      send_confirmation_message(confirm_score(score))
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

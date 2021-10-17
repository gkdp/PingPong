defmodule PingPong.Scoreboard do
  @moduledoc """
  The Scoreboard context.
  """

  import Ecto.Query, warn: false
  alias PingPong.Repo

  alias PingPong.Commands
  alias PingPong.Scoreboard.Score
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
  def get_score!(id), do: Repo.get!(Score, id)

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
  Updates a score.

  ## Examples

      iex> update_score(score, %{field: new_value})
      {:ok, %Score{}}

      iex> update_score(score, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_score(%Score{} = score, attrs) do
    score
    |> Score.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a score.

  ## Examples

      iex> delete_score(score)
      {:ok, %Score{}}

      iex> delete_score(score)
      {:error, %Ecto.Changeset{}}

  """
  def delete_score(%Score{} = score) do
    Repo.delete(score)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking score changes.

  ## Examples

      iex> change_score(score)
      %Ecto.Changeset{data: %Score{}}

  """
  def change_score(%Score{} = score, attrs \\ %{}) do
    Score.changeset(score, attrs)
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def get_user_by_slack(id) when is_binary(id) do
    Repo.get_by(User, slack_id: id)
  end

  def get_or_create_user_by_slack(id) when is_binary(id) do
    with nil <- get_user_by_slack(id) do
      %User{
        slack_id: id
      }
      |> Repo.insert!()
    else
      user -> user
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking score changes.

  ## Examples

      iex> process_score(score)
      %Ecto.Changeset{data: %Score{}}

  """
  def process_score(%Commands.Report{} = report) do
    left = get_or_create_user_by_slack(report.left_id)
    right = get_or_create_user_by_slack(report.right_id)

    winner =
      cond do
        report.left > report.right -> left
        report.left < report.right -> right
        # TODO: Gelijkspel
        true -> left
      end

    loser = if left.id == winner.id, do: left, else: right

    changeset =
      Score.changeset(%Score{}, %{
        left_id: left.id,
        right_id: right.id,
        winner_id: winner.id,
        left_score: report.left,
        right_score: report.right
      })

    score =
      changeset
      |> Repo.insert()

    with {:ok, score} = tuple <- score do
      send_confirm_message(
        {winner, if(left.id == winner.id, do: report.left, else: report.right)},
        {loser, if(left.id != winner.id, do: report.left, else: report.right)},
        score
      )

      tuple
    end
  end

  def send_confirm_message({winner, score_winner}, {loser, score_loser}, _score) do
    message = "Volgens <@#{winner.slack_id}> heb je verloren met #{score_winner}:#{score_loser}. Bevestigen?"

    Chat.post_message(
      loser.slack_id,
      message,
      %{
        blocks:
          Jason.encode!([
            %{
              type: "section",
              text: %{
                type: "plain_text",
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
                  value: "click_me_123"
                },
                %{
                  type: "button",
                  text: %{
                    type: "plain_text",
                    text: "Weiger"
                  },
                  style: "danger",
                  value: "click_me_123"
                }
              ]
            }
          ])
      }
    )
  end
end

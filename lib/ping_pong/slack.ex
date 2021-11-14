defmodule PingPong.Slack do
  @moduledoc """
  The Scoreboard context.
  """

  require Logger

  import Ecto.Query, warn: false

  alias PingPong.Scores.Score
  alias Slack.Web.Chat

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
      "<@#{score.right.user.slack_id}> heeft de score #{score.left_score}:#{score.right_score} bevestigd."
    )
  end

  def send_confirmation_message(%Score{denied_at: time} = score) when not is_nil(time) do
    Chat.post_message(
      score.left.slack_id,
      "<@#{score.right.user.slack_id}> heeft de score #{score.left_score}:#{score.right_score} geweigerd."
    )
  end

  # def scheduled_confirm do
  #   scores =
  #     from(s in Score,
  #       where: s.inserted_at <= ago(1, "day") and is_nil(s.confirmed_at) and is_nil(s.denied_at)
  #     )
  #     |> Repo.all()
  #     |> Repo.preload([:left, :right])

  #   for score <- scores do
  #     Logger.info("Auto confirm score", score_id: score.id)

  #     send_confirmation_message(confirm_score(score))
  #   end
  # end

  defp get_k_factor(wins, elo) do
    cond do
      wins <= 10 -> 60
      elo >= 2000 -> 10
      true -> 25
    end
  end
end

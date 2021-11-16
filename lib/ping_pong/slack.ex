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

  def send_confirmation_message(%Score{confirmed_at: time} = score, slack_id) when not is_nil(time) do
    left =
      Score.get_score_users(score, :left)
      |> Enum.map(&(&1.season_user.user))

    for user <- left do
      Chat.post_message(
        user.slack_id,
        "<@#{slack_id}> heeft de score #{score.left_score}:#{score.right_score} bevestigd."
      )
    end
  end

  def send_confirmation_message(%Score{denied_at: time} = score, slack_id) when not is_nil(time) do
    left =
      Score.get_score_users(score, :left)
      |> Enum.map(&(&1.season_user.user))

    for user <- left do
      Chat.post_message(
        user.slack_id,
        "<@#{slack_id}> heeft de score #{score.left_score}:#{score.right_score} geweigerd."
      )
    end
  end
end

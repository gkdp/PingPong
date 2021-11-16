defmodule PingPongWeb.EventController do
  use PingPongWeb, :controller

  alias PingPong.Scoreboard
  alias PingPong.Scores.Score
  alias PingPong.Slack

  action_fallback PingPongWeb.FallbackController

  def event_action(conn, %{"payload" => payload}) when is_binary(payload) do
    event_action(conn, Jason.decode!(payload))
  end

  def event_action(conn, %{"actions" => [%{"value" => "confirm:" <> id}], "user" => %{"id" => slack_id}} = params) do
    score = Scoreboard.get_score!(id)

    with %Score{confirmed_at: nil, denied_at: nil} <- score, {:ok, final} <- Scoreboard.confirm_score(score) do
      Slack.send_confirmation_message(final, slack_id)
    end

    json =
      Jason.encode!(%{
        "replace_original" => true,
        "blocks" =>
          List.update_at(get_in(params, ["message", "blocks"]), 1, fn block ->
            %{
              "block_id" => block["block_id"],
              "text" => %{
                "type" => "mrkdwn",
                "text" => "*Bevestigd!*"
              },
              "type" => "section"
            }
          end)
      })

    HTTPoison.post!(params["response_url"], json, [{"Content-type", "application/json"}])

    conn
    |> resp(200, "")
  end

  def event_action(conn, %{"actions" => [%{"value" => "deny:" <> id}], "user" => %{"id" => slack_id}} = params) do
    score = Scoreboard.get_score!(id)

    with %Score{confirmed_at: nil, denied_at: nil} <- score, final <- Scoreboard.deny_score(score) do
      Slack.send_confirmation_message(final, slack_id)
    end

    json =
      Jason.encode!(%{
        "replace_original" => true,
        "blocks" =>
          List.update_at(get_in(params, ["message", "blocks"]), 1, fn block ->
            %{
              "block_id" => block["block_id"],
              "text" => %{
                "type" => "mrkdwn",
                "text" => "*Bevestigd!*"
              },
              "type" => "section"
            }
          end)
      })

    HTTPoison.post!(params["response_url"], json, [{"Content-type", "application/json"}])

    conn
    |> resp(200, "")
  end

  def event_action(conn, params) do
    IO.inspect("Fail action")
    IO.inspect(params)

    conn
    |> resp(200, "")
  end

  def event(conn, %{"challenge" => challenge} = _params) do
    conn
    |> resp(200, challenge)
  end

  def event(conn, params) do
    IO.inspect("Fail event")
    IO.inspect(params)

    conn
    |> resp(200, "")
  end
end

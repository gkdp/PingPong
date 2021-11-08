defmodule PingPongWeb.CommandController do
  use PingPongWeb, :controller

  alias PingPong.Commands
  alias PingPong.Scoreboard

  action_fallback PingPongWeb.FallbackController

  def command(conn, %{"command" => "/match", "text" => "report" <> text} = params) do
    with %Commands.Report{} = command <- report(text, params),
         {:ok, score} <- Scoreboard.process_score(command) do
      conn
      |> render("report.json", score: PingPong.Repo.preload(score, [:left, :right]))
    else
      {:error, :equals} ->
        conn
        |> render("equals.json")

      _ ->
        conn
        |> render("error.json")
    end
  end

  def command(conn, %{"command" => "/match", "text" => "score" <> text} = params) do
    processed =
      Regex.named_captures(
        ~r/<@(?<id>.+)\|(?<name>.+)>/,
        String.trim(String.replace(text, <<160::utf8>>, " "))
      )

    with %{"id" => id} <- processed do
      case Scoreboard.get_or_create_user_by_slack(id) do
        {:ok, user} ->
          conn
          |> render("player_score.json", slack_id: user.slack_id, elo: user.elo)
        {:error, _} ->
          conn
          |> render("error.json")
      end
    else
      _ ->
        case Scoreboard.get_or_create_user_by_slack(params["user_id"]) do
          {:ok, user} ->
            conn
            |> render("personal_score.json", elo: user.elo)
          {:error, _} ->
            conn
            |> render("error.json")
        end
    end
  end

  def command(conn, _) do
    conn
    |> render("help.json")
  end

  defp report(text, params) do
    processed =
      Regex.named_captures(
        ~r/<@(?<id>.+)\|(?<name>.+)>(\s+?)(?<own>\d+):(?<other>\d+)/,
        String.trim(String.replace(text, <<160::utf8>>, " "))
      )

    with %{} <- processed, user_id <- params["user_id"] do
      %Commands.Report{
        left_id: user_id,
        right_id: Map.get(processed, "id"),
        left: String.to_integer(Map.get(processed, "own")),
        right: String.to_integer(Map.get(processed, "other"))
      }
    end
  end
end

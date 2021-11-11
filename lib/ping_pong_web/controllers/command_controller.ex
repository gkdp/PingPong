defmodule PingPongWeb.CommandController do
  use PingPongWeb, :controller

  alias PingPong.Commands.Report
  alias PingPong.Scoreboard

  action_fallback PingPongWeb.FallbackController

  def command(conn, %{"command" => "/match", "text" => "report" <> text} = params) do
    with %Report{} = report <- report(text, params) do
      with {:ok, scores} <- Scoreboard.process_scores(report) do
        conn
        |> render("report.json", scores: PingPong.Repo.preload(scores, [:left, :right]))
      else
        {:error, :equals} ->
          conn
          |> render("equals.json")

        _ ->
          conn
          |> render("error.json")
      end
    end
  end

  # def command(conn, %{"command" => "/match", "text" => "report" <> text} = params) do
  #   with %Commands.Report{} = command <- report(text, params),
  #        {:ok, score} <- Scoreboard.process_score(command) do
  #     conn
  #     |> render("report.json", score: PingPong.Repo.preload(score, [:left, :right]))
  #   else
  #     {:error, :equals} ->
  #       conn
  #       |> render("equals.json")

  #     _ ->
  #       conn
  #       |> render("error.json")
  #   end
  # end

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
        ~r/<@(?<id>.+)\|(?<name>.+)>(\s+?)(?<scores>.*)/,
        String.trim(String.replace(text, <<160::utf8>>, " "))
      )

    with %{"id" => right_id, "scores" => scores} <- processed, left_id <- params["user_id"] do
      scores =
        for score <- String.split(scores, ~r/\s+/) do
          with %{"left" => left, "right" => right} <-
                 Regex.named_captures(~r/(?<left>\d+):(?<right>\d+)/, score) do
            %Report.Score{
              left: String.to_integer(left),
              right: String.to_integer(right)
            }
          end
        end

      %Report{
        left_id: left_id,
        right_id: right_id,
        scores: Enum.filter(scores, &(!is_nil(&1)))
      }
    end
  end
end

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
        |> resp(200, "")
    end
  end

  def command(conn, _) do
    IO.inspect("Fail")

    conn
    |> resp(200, "")
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

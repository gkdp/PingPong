defmodule PingPongWeb.CommandView do
  use PingPongWeb, :view
  alias PingPongWeb.CommandView

  alias PingPong.Scoreboard.Score

  def render("index.json", %{commands: commands}) do
    %{data: render_many(commands, CommandView, "command.json")}
  end

  def render("show.json", %{command: command}) do
    %{data: render_one(command, CommandView, "command.json")}
  end

  def render("command.json", %{command: command}) do
    %{
      id: command.id,
      response_type: command.response_type
    }
  end

  def render("match.json", %{command: _command}) do
    %{
      response_type: "in_channel",
      text: "Matched."
    }
  end

  def render("report.json", %{score: %Score{} = score}) do
    score_winner = if score.winner_id == score.left_id, do: score.left_score, else: score.right_score
    score_loser = if score.winner_id != score.left_id, do: score.left_score, else: score.right_score
    loser_id = if score.winner_id == score.right_id, do: score.left.slack_id, else: score.right.slack_id

    %{
      response_type: "in_channel",
      text:
        "<@#{score.winner.slack_id}> heeft gewonnen met #{score_winner}:#{score_loser}. <@#{loser_id}> moet dit bevestigen. Dit gebeurt anders automatisch na 24 uur."
    }
  end
end

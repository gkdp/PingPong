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

  def render("personal_score.json", %{elo: elo}) do
    %{
      response_type: "ephemeral",
      text:
        "Je score is op dit moment *#{elo}*."
    }
  end

  def render("player_score.json", %{slack_id: slack_id, elo: elo}) do
    %{
      response_type: "ephemeral",
      text:
        "De score van <@#{slack_id}> is op dit moment *#{elo}*."
    }
  end

  def render("equals.json", _) do
    %{
      response_type: "ephemeral",
      text:
        "Gek! Je kan niet tegen jezelf spelen! Behalve als je de Flash bent?"
    }
  end

  def render("help.json", _) do
    %{
      response_type: "ephemeral",
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: "De volgende commando's zijn beschikbaar:"
          }
        },
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: "• `/match score`; Bekijk je score \n • `/match score @Gebruiker`; Bekijk de score van Gebruiker \n • `/match report @Gebruiker 21:10`; Rapporteer een score waarbij je met 21 punten hebt gewonnen"
          }
        }
      ]
    }
  end

  def render("error.json", _) do
    %{
      response_type: "ephemeral",
      text:
        "Iets ging mis bij het verwerken..."
    }
  end

  def render("report.json", %{score: %Score{winner: winner} = score}) do
    {winning_user, winning_score} = if(winner == :left, do: {score.left, score.left_score}, else: {score.right, score.right_score})
    {_losing_user, losing_score} = if(winner != :left, do: {score.left, score.left_score}, else: {score.right, score.right_score})

    %{
      response_type: "in_channel",
      text:
        "<@#{winning_user.slack_id}> heeft gewonnen met #{winning_score}:#{losing_score}. <@#{score.right.slack_id}> moet dit bevestigen. Dit gebeurt anders automatisch na 24 uur."
    }
  end
end

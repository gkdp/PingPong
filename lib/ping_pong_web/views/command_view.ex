defmodule PingPongWeb.CommandView do
  use PingPongWeb, :view
  import PingPongWeb.LiveHelpers, only: [humanize_list: 2]

  alias PingPong.Scores.Score

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

  def render("season_not_found.json", _) do
    %{
      response_type: "ephemeral",
      text:
        "Er is op dit moment geen seizoen aan de gang."
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
            text: "• `/match score`; Bekijk je score \n • `/match score @Gebruiker`; Bekijk de score van Gebruiker \n • `/match report @Gebruiker 21:10`; Rapporteer een score waarbij je met 21 punten hebt gewonnen \n • `/match doubles @Buddy report @Tegenstander @TegenstanderBuddy 21:10`; Rapporteer een score waarbij je met 21 punten hebt gewonnen met dubbels"
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

  def render("report.json", %{scores: scores}) do
    {winners, losers} =
      for %Score{winner: winner} = score <- scores, reduce: {[], []} do
        {prev_winners, prev_losers} ->
          winners =
            for %{season_user: season_user} <- Score.get_score_users(score, winner) do
              season_user.user
            end

          losers =
            for %{season_user: season_user} <- Score.get_score_users(score, if(winner == :left, do: :right, else: :left)) do
              season_user.user
            end

          {winners ++ prev_winners, losers ++ prev_losers}
      end

    text =
      "#{humanize_list(winners, &("<@#{&1.slack_id}>"))} heeft gewonnen van #{humanize_list(losers, &("<@#{&1.slack_id}>"))}"

    %{
      response_type: "in_channel",
      text: text
    }
  end
end

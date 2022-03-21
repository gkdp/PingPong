defmodule PingPongWeb.ScoreboardLive.Components do
  use Phoenix.Component
  import PingPongWeb.LiveHelpers, only: [humanize_list: 2]

  alias PingPong.Seasons.SeasonUser
  alias PingPong.Scoreboard.User
  alias PingPong.Scores.Score

  def user_row(%{user: %SeasonUser{user: user} = season_user} = assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-8 rounded items-center">
        <%= if Map.has_key?(assigns, :position) do %>
          <div class="text-center">
            <span class={"#{get_position_styling(@position)} font-bold"}><%= @position %></span>
          </div>
        <% end %>

        <div class="col-span-4 px-3">
          <a class="text-md hover:underline dark:text-white" href="#" x-on:click.prevent={"expanded = expanded == #{season_user.id} ? null : #{season_user.id}; update()"}><%= User.get_slack_name(user) %></a>

          <%= if Ecto.assoc_loaded?(user.teams) and not Enum.empty?(user.teams) and not Map.get(assigns, :hide_teams, false) do %>
            <p class="text-xs text-gray-500 dark:text-gray-500"><%= Enum.join(Enum.map(user.teams, & "Team #{&1.name}"), ", ") %></p>
          <% end %>
        </div>
        <div class="text-center relative rounded overflow-hidden">
          <p class="relative font-semibold dark:text-white text-md z-10 text-shadow pointer-events-none"><%= season_user.elo %></p>

          <div class="sparkline-container absolute">
            <svg class="sparkline" width="100" height="24" stroke-width="1" x-data x-sparkline={"[#{get_values(season_user, @lowest_elo)}]"} />
          </div>
        </div>
        <span class="tooltip" hidden="true"></span>
        <div class="text-center">
          <p class="text-md font-semibold dark:text-white"><%= season_user.count_won %></p>
        </div>
        <div class="text-center">
          <p class="text-md font-semibold dark:text-white"><%= season_user.count_lost %></p>
        </div>
      </div>

      <div x-show={"expanded == #{season_user.id}"} class="relative before-nip mt-4" style="display: none;">
        <div class="bg-gray-100 p-6 text-sm">
          <%= get_last_played_text(season_user, @others) %> <%= get_opponent_text(season_user, @position, @others) %>
        </div>

        <div class="bg-gray-100 p-6 pt-0 text-sm">
          <%= live_redirect "Ga naar profiel", to: PingPongWeb.Router.Helpers.player_player_path(@socket, :show, user.id) %>
        </div>

        <% last_scores = SeasonUser.get_scores(season_user, 5) %>

        <%= if length(last_scores) > 1 do %>
          <div class="bg-gray-100 px-6 pb-6 text-sm">
            <p><%= length(last_scores) %> laatst gespeelde matches:</p>

            <table class="table mt-2 w-1/2">
              <%= for score <- SeasonUser.get_scores(season_user, 5) do %>
                <tr>
                  <td class="whitespace-nowrap pr-4" style="width: 1%;"><%= get_score_text(season_user, score) %></td>
                  <td><%= get_opponents_text(season_user, score, @others) %></td>
                </tr>
              <% end %>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def user_minimal_row(
        %{score: score, season_users: season_users, season_user: season_user} = assigns
      ) do
    ~H"""
    <div>
      <div class="grid grid-cols-5 rounded items-center">
        <div class="col-span-3 px-3">
          <%= Enum.join(Enum.map(season_users, &User.get_slack_name(&1.user)), ", ") %>
        </div>
        <div class="text-center">
          <p class="text-md dark:text-white">
            <%= get_status(season_user, score) %>
          </p>
        </div>
        <div class="text-center">
          <p class="text-md font-semibold dark:text-white"><%= get_score_text(season_user, score) %></p>
        </div>
      </div>
    </div>
    """
  end

  defp get_last_played_text(season_user, others) do
    with %Score{} = score <- SeasonUser.get_last_score(season_user) do
      side = Score.get_side(score, season_user)

      players =
        for %{season_user_id: id} <- Score.get_score_users(score, side) do
          Enum.find(others, &(&1.id == id))
        end

      opponents =
        for %{season_user_id: id} <-
              Score.get_score_users(score, if(side == :left, do: :right, else: :left)) do
          Enum.find(others, &(&1.id == id))
        end

      score_in_text =
        if side == :left do
          "#{score.left_score}:#{score.right_score}"
        else
          "#{score.right_score}:#{score.left_score}"
        end

      score_text =
        if score.winner == side do
          "<span class=\"font-semibold\">" <> score_in_text <> "</span> gewonnen"
        else
          "<span class=\"font-semibold\">" <> score_in_text <> "</span> verloren"
        end

      Phoenix.HTML.raw("""
      #{User.get_slack_name_short(season_user.user)} #{if length(players) == 1, do: "heeft", else: "hebben"} voor
      het laatst gespeeld tegen #{humanize_list(opponents, &User.get_slack_name_short(&1.user))}
      en #{if length(players) == 1, do: "heeft", else: "hebben"} met #{score_text}.
      """)
    else
      _ ->
        "#{User.get_slack_name_short(season_user.user)} heeft nog niet gespeeld."
    end
  end

  def get_status(season_user, score) do
    side = Score.get_side(score, season_user)

    if score.winner == side do
      "Gewonnen"
    else
      "Verloren"
    end
  end

  def get_score_text(season_user, score) do
    side = Score.get_side(score, season_user)

    score_in_text =
      if side == :left do
        "#{score.left_score}:#{score.right_score}"
      else
        "#{score.right_score}:#{score.left_score}"
      end

    score_text =
      if score.winner == side do
        "<span class=\"font-semibold\">" <> score_in_text <> "</span>"
      else
        "<span class=\"font-semibold\">" <> score_in_text <> "</span>"
      end

    Phoenix.HTML.raw(score_text)
  end

  def get_opponents_text(season_user, score, others) do
    side = Score.get_side(score, season_user)

    opponents =
      for %{season_user_id: id} <-
            Score.get_score_users(score, if(side == :left, do: :right, else: :left)) do
        Enum.find(others, &(&1.id == id))
      end

    humanize_list(opponents, &User.get_slack_name_short(&1.user))
  end

  def get_opponent_text(season_user, position, others) do
    if position == 1 do
      "#{User.get_slack_name_short(season_user.user)} staat eerste!"
    else
      other = Enum.at(others, position - 2)

      win_rate =
        (Elo.expected_result(season_user.elo, other.elo) * 100)
        |> round()

      "#{User.get_slack_name_short(season_user.user)} heeft #{win_rate}% kans om positie #{position - 1} (#{User.get_slack_name_short(other.user)}) te veroveren."
    end
  end

  defp get_values(season_user, lowest_elo) do
    history =
      if length(season_user.elo_history) < 10 do
        [%{elo: 1000, inserted_at: season_user.inserted_at}] ++ season_user.elo_history
      else
        season_user.elo_history
      end

    values =
      for %{elo: elo, inserted_at: date} <- history do
        "{date: \"#{date}\", original: #{elo}, value: #{elo - lowest_elo}}"
      end

    Enum.join(values, ",")
  end

  defp get_position_styling(position) do
    case position do
      1 -> "text-3xl text-black dark:text-white"
      2 -> "text-2xl text-gray-800 dark:text-gray-300"
      3 -> "text-xl text-gray-600 dark:text-gray-400"
      _ -> "text-lg text-gray-400 dark:text-gray-500"
    end
  end
end

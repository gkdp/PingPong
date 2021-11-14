defmodule PingPongWeb.ScoreboardLive.Components do
  use Phoenix.Component

  alias PingPong.Seasons.SeasonUser
  alias PingPong.Scoreboard.User

  def user_row(%{user: %SeasonUser{user: user} = season_user} = assigns) do
    ~H"""
    <div class="grid grid-cols-8 rounded items-center">
      <div class="text-center">
        <span class={"#{get_position_styling(@position)} font-bold"}><%= @position %></span>
      </div>
      <div class="col-span-4 px-3">
        <p class="text-md dark:text-white"><%= User.get_slack_name(user) %></p>

        <%= if Ecto.assoc_loaded?(user.teams) and not Enum.empty?(user.teams) and Map.get(assigns, :show_teams, false) do %>
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
        <p class="text-md font-semibold dark:text-white"><%= Enum.count(season_user.winnings) %></p>
      </div>
      <div class="text-center">
        <p class="text-md font-semibold dark:text-white"><%= Enum.count(season_user.losses) %></p>
      </div>
    </div>
    """
  end

  defp get_values(season_user, lowest_elo) do
    values =
      for %{elo: elo, inserted_at: date} <- season_user.elo_history do
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

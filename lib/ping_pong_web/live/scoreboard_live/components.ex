defmodule PingPongWeb.ScoreboardLive.Components do
  use Phoenix.Component

  alias PingPong.Scoreboard.User

  def user(%{user: %User{} = user} = assigns) do
    ~H"""
    <div class="grid grid-cols-8 rounded items-center">
      <div class="text-center">
        <span class={"#{get_position_styling(@position)} font-bold text-grey-dark"}><%= @position %></span>
      </div>
      <div class="col-span-4 px-3">
        <p class="text-md"><%= User.get_slack_name(user) %></p>
      </div>
      <div class="text-center relative rounded overflow-hidden">
        <p class="relative font-semibold text-md text-grey-dark z-10 text-shadow pointer-events-none"><%= user.elo %></p>

        <div class="sparkline-container absolute">
          <svg class="sparkline" width="100" height="24" stroke-width="1" x-data x-sparkline={"[#{get_values(user, @lowest_elo)}]"} />
        </div>
      </div>
      <span class="tooltip" hidden="true"></span>
      <div class="text-center">
        <p class="text-md font-semibold text-grey-dark"><%= Enum.count(user.winnings) %></p>
      </div>
      <div class="text-center">
        <p class="text-md font-semibold text-grey-dark"><%= Enum.count(user.losses) %></p>
      </div>
    </div>
    """
  end

  defp get_values(user, lowest_elo) do
    values =
      for %{elo: elo, inserted_at: date} <- user.elo_history do
        "{date: \"#{date}\", original: #{elo}, value: #{elo - lowest_elo}}"
      end

    Enum.join(values, ",")
  end

  defp get_position_styling(position) do
    case position do
      1 -> "text-3xl text-black"
      2 -> "text-2xl text-gray-800"
      3 -> "text-xl text-gray-600"
      _ -> "text-lg text-gray-400"
    end
  end
end

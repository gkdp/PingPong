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
        <p class="relative font-semibold text-md text-grey-dark z-10 text-shadow"><%= user.elo %></p>

        <svg class="absolute sparkline" width="110" height="24" stroke-width="1" x-data x-sparkline={"[#{Enum.join(Enum.map(user.elo_history, fn a -> a.elo - @lowest_elo end), ",")}]"} />
      </div>
      <div class="text-center">
        <p class="text-md font-semibold text-grey-dark"><%= Enum.count(user.winnings) %></p>
      </div>
      <div class="text-center">
        <p class="text-md font-semibold text-grey-dark"><%= Enum.count(user.losses) %></p>
      </div>
    </div>
    """
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

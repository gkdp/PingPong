defmodule PingPongWeb.ScoreboardLive.Components do
  use Phoenix.Component

  alias PingPong.Scoreboard.User

  def user(%{user: %User{} = user} = assigns) do
    ~H"""
    <div class="grid grid-cols-6 rounded items-center">
      <div class="text-center">
        <span class={"#{if @position == 1, do: "text-3xl", else: "text-lg"} font-bold text-grey-dark"}><%= @position %></span>
      </div>
      <div class="col-span-2 px-3">
        <p class="text-md"><%= User.get_slack_name(user) %></p>
      </div>
      <div class="text-center">
        <p class="text-md text-grey-dark"><%= user.elo %></p>
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
end

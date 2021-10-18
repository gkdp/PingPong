defmodule PingPongWeb.ScoreboardLive.Components do
  use Phoenix.Component

  alias PingPong.Scoreboard.User

  def user(%{user: %User{} = user} = assigns) do
    ~H"""
    <%= live_redirect to: @show, class: "flex cursor-pointer my-1 hover:bg-blue-100 rounded items-center pointer-events-none" do %>
      <div class="w-1/12 text-center">
        <span class={"#{if @position == 1, do: "text-2xl", else: "text-lg"} font-bold text-grey-dark"}><%= @position %></span>
      </div>
      <div class="w-8/12 py-3 px-3">
        <p class="hover:text-blue-dark"><%= User.get_slack_name(user) %></p>
        <span class="text-sm text-gray-400">ELO <%= user.elo %></span>
      </div>
      <div class="w-3/12 text-right px-3">
        <p class="text-sm text-grey-dark"><%= Enum.count(user.winnings) %> gewonnen</p>
      </div>
    <% end %>
    """
  end
end

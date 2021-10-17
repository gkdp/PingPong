defmodule PingPongWeb.TeamLive.Components do
  use Phoenix.Component

  alias PingPong.Accounts.User
  alias PingPong.Teams.Team

  def team(%{team: %Team{}} = assigns) do
    ~H"""
    <%= live_redirect to: @show, class: "flex cursor-pointer my-1 hover:bg-blue-100 rounded items-center" do %>
      <div class="w-4/5 py-3 px-3">
        <p class="hover:text-blue-dark"><%= @team.name %></p>
      </div>
      <div class="w-1/5 text-right px-3">
        <p class="text-sm text-grey-dark">Member</p>
      </div>
    <% end %>
    """
  end

  def user(%{user: %User{}} = assigns) do
    ~H"""
    <%= live_redirect to: @show, class: "flex cursor-pointer my-1 hover:bg-blue-100 rounded items-center" do %>
      <div class="w-4/5 py-3 px-3">
        <p class="hover:text-blue-dark"><%= @user.name %></p>
      </div>
      <div class="w-1/5 text-right px-3">
        <p class="text-sm text-grey-dark">Member</p>
      </div>
    <% end %>
    """
  end
end

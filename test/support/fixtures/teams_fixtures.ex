defmodule PingPong.TeamsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PingPong.Teams` context.
  """

  @doc """
  Generate a team.
  """
  def team_fixture(attrs \\ %{}) do
    {:ok, team} =
      attrs
      |> Enum.into(%{
        name: "some name",
        slack_bot_id: "some slack_bot_id",
        slack_channel_id: "some slack_channel_id"
      })
      |> PingPong.Teams.create_team()

    team
  end
end

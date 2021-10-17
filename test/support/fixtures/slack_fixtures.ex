defmodule PingPong.SlackFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PingPong.Slack` context.
  """

  @doc """
  Generate a command.
  """
  def command_fixture(attrs \\ %{}) do
    {:ok, command} =
      attrs
      |> Enum.into(%{
        response_type: "some response_type"
      })
      |> PingPong.Slack.create_command()

    command
  end
end

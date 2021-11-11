defmodule PingPong.CompetitionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PingPong.Competitions` context.
  """

  @doc """
  Generate a competition.
  """
  def competition_fixture(attrs \\ %{}) do
    {:ok, competition} =
      attrs
      |> Enum.into(%{
        end_at: ~N[2021-11-09 14:55:00],
        start_at: ~N[2021-11-09 14:55:00]
      })
      |> PingPong.Competitions.create_competition()

    competition
  end
end

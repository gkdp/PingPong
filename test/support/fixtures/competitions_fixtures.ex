defmodule PingPong.SeasonsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PingPong.Seasons` context.
  """

  @doc """
  Generate a season.
  """
  def season_fixture(attrs \\ %{}) do
    {:ok, season} =
      attrs
      |> Enum.into(%{
        end_at: ~N[2021-11-09 14:55:00],
        start_at: ~N[2021-11-09 14:55:00]
      })
      |> PingPong.Seasons.create_season()

    season
  end
end

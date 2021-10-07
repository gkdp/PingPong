defmodule PingPong.ScoreboardFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PingPong.Scoreboard` context.
  """

  @doc """
  Generate a score.
  """
  def score_fixture(attrs \\ %{}) do
    {:ok, score} =
      attrs
      |> Enum.into(%{
        left: 42,
        right: 42
      })
      |> PingPong.Scoreboard.create_score()

    score
  end
end

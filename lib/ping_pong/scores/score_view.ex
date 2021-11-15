defmodule PingPong.Scores.ScoreView do
  use Ecto.Schema

  alias PingPong.Seasons.SeasonUser

  schema "scores_extra" do
    field :winner, Ecto.Enum, values: [:left, :right, :draw]
    field :left_score, :integer
    field :right_score, :integer
    field :confirmed_at, :naive_datetime
    field :denied_at, :naive_datetime

    belongs_to :left, SeasonUser
    belongs_to :right, SeasonUser
    belongs_to :won_by, SeasonUser
    belongs_to :lost_by, SeasonUser

    timestamps()
  end

  def get_other_user(%__MODULE__{won_by_id: won_by_id, lost_by_id: lost_by_id}, user, others) do
    cond do
      won_by_id == user.id ->
        Enum.find(others, &(&1.id == lost_by_id))

        lost_by_id == user.id ->
        Enum.find(others, &(&1.id == won_by_id))

      true ->
        user
    end
  end
end

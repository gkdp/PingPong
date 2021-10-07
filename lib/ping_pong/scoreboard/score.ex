defmodule PingPong.Scoreboard.Score do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scores" do
    field :left, :integer
    field :right, :integer

    timestamps()
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:left, :right])
    |> validate_required([:left, :right])
  end
end

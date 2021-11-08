defmodule PingPong.Scoreboard.EloHistory do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.User

  schema "elo_history" do
    field :elo, :integer, default: 1000

    belongs_to :user, User
    belongs_to :score, User

    timestamps()
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:elo, :user_id, :score_id])
    |> validate_required([:elo, :user_id, :score_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:score)
  end
end

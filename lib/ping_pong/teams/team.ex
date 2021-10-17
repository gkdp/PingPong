defmodule PingPong.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :slack_bot_id, :string
    field :slack_channel_id, :string

    many_to_many :users, PingPong.Accounts.User, join_through: "team_user"

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:slack_channel_id, :slack_bot_id, :name])
    |> validate_required([:slack_channel_id, :slack_bot_id, :name])
  end
end

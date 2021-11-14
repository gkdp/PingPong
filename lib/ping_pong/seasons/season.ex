defmodule PingPong.Seasons.Season do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Seasons.SeasonUser

  schema "seasons" do
    field :title, :string
    field :description, :string
    field :start_at, :naive_datetime
    field :end_at, :naive_datetime

    has_many :season_users, SeasonUser
    has_many :users, through: [:season_users, :user]

    timestamps()
  end

  @doc false
  def changeset(season, attrs) do
    season
    |> cast(attrs, [:title, :start_at, :end_at])
    |> validate_required([:start_at, :end_at])
  end
end

defmodule PingPong.Scoreboard.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :slack_id, :string
    field :email, :string
    field :name, :string

    field :winnings, :integer, virtual: true
    field :loses, :integer, virtual: true

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slack_id, :name, :email])
  end

  def get_slack_name(%__MODULE__{slack_id: id}) do
    {_, user} =
      Cachex.fetch(:slack_profiles, id, fn _ ->
        with %{"ok" => true, "user" => user} <- Slack.Web.Users.info(id) do
          {:commit, user}
        else
          _ -> {:ignore, nil}
        end
      end)

      case user do
        %{"profile" => %{"real_name" => name}} -> name
        _ -> "Naam niet bekend"
      end
  end
end

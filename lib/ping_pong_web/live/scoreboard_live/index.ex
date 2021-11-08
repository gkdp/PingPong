defmodule PingPongWeb.ScoreboardLive.Index do
  use PingPongWeb, :live_view

  alias PingPong.Scoreboard

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, users: list_users(), changeset: changeset(), win_rate: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"vs" => vs}, socket) do
    changeset = changeset(vs)

    win_rate =
      with %{left_id: left_id, right_id: right_id} when not is_nil(left_id) and not is_nil(right_id) <-
           Ecto.Changeset.apply_changes(changeset) do
        left = Enum.find(socket.assigns.users, & &1.id == String.to_integer(left_id))
        right = Enum.find(socket.assigns.users, & &1.id == String.to_integer(right_id))

        Elo.expected_result(left.elo, right.elo) * 100
        |> Float.ceil(2)
      else
        _ -> nil
      end

    {:noreply,
     socket
     |> assign(:win_rate, win_rate)
     |> assign(:changeset, changeset)
    }
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Scoreboard")
    |> assign(:team, nil)
  end

  defp list_users do
    Scoreboard.list_users()
  end

  @types %{left_id: :string, right_id: :string}
  defp changeset(params \\ %{}) do
    {%{}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
  end
end

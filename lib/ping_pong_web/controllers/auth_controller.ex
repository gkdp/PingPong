defmodule PingPongWeb.AuthController do
  use PingPongWeb, :controller

  alias PingPong.Scoreboard
  alias PingPong.Users

  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case auth do
      %{credentials: %{other: %{user_info: info}}} ->
        {:ok, user} = Scoreboard.get_or_create_user_by_slack(info["sub"])

        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> PingPong.Guardian.Plug.sign_in(user, %{picture: info["https://slack.com/user_image_48"]})
        |> redirect(to: "/")

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  def logout(conn, _params) do
    conn
    |> put_flash(:info, "Successfully logged out.")
    |> PingPong.Guardian.Plug.sign_out()
    |> redirect(to: "/")
  end

  def dev(conn, _params) do
    user = Users.get_user(1)

    conn
    |> put_flash(:info, "Successfully authenticated.")
    |> PingPong.Guardian.Plug.sign_in(user, %{picture: "https://avatars.slack-edge.com/2021-09-22/2518454877683_7528df9e5e0fad98e703_48.jpg"})
    |> redirect(to: "/")
  end
end

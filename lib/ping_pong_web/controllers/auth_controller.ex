defmodule PingPongWeb.AuthController do
  use PingPongWeb, :controller

  alias PingPong.Scoreboard

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
end

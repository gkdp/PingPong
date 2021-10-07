defmodule PingPong.Repo do
  use Ecto.Repo,
    otp_app: :ping_pong,
    adapter: Ecto.Adapters.Postgres
end

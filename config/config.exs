# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ping_pong,
  ecto_repos: [PingPong.Repo]

# Configures the endpoint
config :ping_pong, PingPongWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: PingPongWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PingPong.PubSub,
  live_view: [signing_salt: "xKtRlX3f"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ping_pong, PingPong.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure Ueberauth
config :ueberauth, Ueberauth,
  providers: [
    slack: {Ueberauth.Strategy.SlackV2, []}
  ]

# Configure Ueberauth for Slack
config :ueberauth, Ueberauth.Strategy.SlackV2.OAuth,
  client_id: System.get_env("SLACK_CLIENT_ID"),
  client_secret: System.get_env("SLACK_CLIENT_SECRET")

config :slack,
  api_token: System.get_env("SLACK_API_TOKEN")
  # web_http_client_opts: [
  #   proxy: {"172.23.32.43", 9090},
  #   ssl: [
  #     certfile: "proxyman-key.pem"
  #   ]
  # ]

config :ping_pong, PingPong.Scheduler,
  jobs: [
    # {"* * * * *", {PingPong.Scoreboard, :scheduled_confirm, []}}
  ]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

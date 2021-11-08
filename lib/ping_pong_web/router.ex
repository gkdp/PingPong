defmodule PingPongWeb.Router do
  use PingPongWeb, :router

  import PingPongWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PingPongWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PingPongWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PingPongWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PingPongWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", PingPongWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    # get "/users/log_in", UserSessionController, :new
    # post "/users/log_in", UserSessionController, :create
  end

  # scope "/auth", PingPongWeb do
  #   pipe_through [:browser]

  #   get "/:provider", SlackController, :request
  #   get "/:provider/callback", SlackController, :callback
  # end

  scope "/", PingPongWeb do
    pipe_through [:browser]

    live "/scoreboard", ScoreboardLive.Index, :index

    live "/teams", TeamLive.Index, :index
    live "/teams/new", TeamLive.Index, :new
    # live "/teams/:id/edit", TeamLive.Index, :edit

    live "/teams/:id", TeamLive.Show, :show
    # live "/teams/:id/show/edit", TeamLive.Show, :edit

    # live "/scores", ScoreLive.Index, :index
    # live "/scores/new", ScoreLive.Index, :new
    # live "/scores/:id/edit", ScoreLive.Index, :edit

    # live "/scores/:id", ScoreLive.Show, :show
    # live "/scores/:id/show/edit", ScoreLive.Show, :edit
  end

  scope "/slack", PingPongWeb do
    pipe_through [:api]

    post "/command", CommandController, :command
    post "/event", EventController, :event
    post "/event/action", EventController, :event_action
  end
end

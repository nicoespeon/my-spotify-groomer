defmodule MySpotifyGroomer.Router do
  use MySpotifyGroomer.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MySpotifyGroomer do
    pipe_through :browser # Use the default browser stack

    get "/", SpotifyController, :index
    get "/login", SpotifyController, :login
    get "/login-with-spotify", SpotifyController, :login_with_spotify
  end

  # Other scopes may use custom stacks.
  # scope "/api", MySpotifyGroomer do
  #   pipe_through :api
  # end
end

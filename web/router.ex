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
    pipe_through :browser

    get "/", SpotifyController, :index
    get "/login", SpotifyController, :login
    get "/login-with-spotify", SpotifyController, :login_with_spotify
  end

  scope "/fake-spotify-api", MySpotifyGroomer do
    pipe_through :api

    get "/me", FakeSpotifyApiController, :me
    get "/me/top/tracks", FakeSpotifyApiController, :me_top_tracks
    get "/me/playlists", FakeSpotifyApiController, :me_playlists
    get "/users/:user_id/playlists/:playlist_id/tracks", FakeSpotifyApiController, :user_playlist_tracks
    delete "/users/:user_id/playlists/:playlist_id/tracks", FakeSpotifyApiController, :user_playlist_tracks_delete
  end
end

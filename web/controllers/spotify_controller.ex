defmodule MySpotifyGroomer.SpotifyController do
    use MySpotifyGroomer.Web, :controller

    def index(conn, _params) do
        render conn, "index.html"
    end

    def login(conn, _params) do
        render conn, "login.html"
    end

    def login_with_spotify(conn, _params) do
        # Uses the Implicit Grant Flow: https://developer.spotify.com/web-api/authorization-guide/#implicit-grant-flow
        # Downside => token can't be refreshed
        # To protect users against CSRF, we should use the `state` param.
        spotify_uri = "https://accounts.spotify.com/authorize?"
        spotify_params = URI.encode_query %{
            "client_id" => "b0cfa00850ee49009f88a7747681d01b",
            "response_type" => "token",
            "redirect_uri" => MySpotifyGroomer.Router.Helpers.url(conn),
            "scope" => "user-read-private user-read-email playlist-read-private playlist-read-collaborative"
        }

        redirect conn, external: spotify_uri <> spotify_params
    end
end

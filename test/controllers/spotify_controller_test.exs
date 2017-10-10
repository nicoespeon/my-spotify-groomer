defmodule MySpotifyGroomer.SpotifyControllerTest do
  use MySpotifyGroomer.ConnCase

  test "GET / should render main page", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "<div id=\"my-spotify-groomer\"></div>"
  end
end

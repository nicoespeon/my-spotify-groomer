module MySpotifyGroomerTests exposing (..)

import Test exposing (..)
import ElmTestBDDStyle exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text)
import MySpotifyGroomer exposing (..)


suite : Test
suite =
    describe "MySpotifyGroomer"
        [ it "passes" <|
            let
                resultHtml =
                    Query.fromHtml (view "")
            in
                expect resultHtml to Query.has [ text "" ]
        ]

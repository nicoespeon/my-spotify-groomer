defmodule MySpotifyGroomer.FakeSpotifyApiController do
    use MySpotifyGroomer.Web, :controller

    def api_url(conn) do
        MySpotifyGroomer.Router.Helpers.url(conn) <> "/fake-spotify-api"
    end

    def me(conn, _params) do
        json conn, %{
            "birthdate": "1991-03-06",
            "country": "FR",
            "display_name": "Nicolas Carlo",
            "email": "contact.ncarlo@gmail.com",
            "external_urls": %{
                "spotify": "https://open.spotify.com/user/nicoespeon"
            },
            "followers": %{
                "href": nil,
                "total": 14
            },
            "href": "#{api_url(conn)}/users/nicoespeon",
            "id": "nicoespeon",
            "images": [
                %{
                    "height": nil,
                    "url": "https://scontent.xx.fbcdn.net/v/t1.0-1/p200x200/20622237_10155695383863987_3273562608981421615_n.jpg?_nc_cat=0&oh=dd8cdf5f5a6ad7e40250f8836fa2f3ce&oe=5B2AA708",
                    "width": nil
                }
            ],
            "product": "premium",
            "type": "user",
            "uri": "spotify:user:nicoespeon"
        }
    end

    def me_top_tracks(conn, _params) do
        json conn, %{
            "items": [
                %{
                    "album": %{
                        "album_type": "COMPILATION",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/3q8A9evB3WDkCXdTCG6nNt"
                        },
                        "href": "#{api_url(conn)}/albums/3q8A9evB3WDkCXdTCG6nNt",
                        "id": "3q8A9evB3WDkCXdTCG6nNt",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/acd99481322eb5b4f1a3cba848d8ef4e18f4b51b",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/348a3add0c1e90caf3fb33c7be9e5a2e2f45b454",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/efb351c80e1482326520a0bee6225f01fc7d9c16",
                                "width": 64
                            }
                        ],
                        "name": "Cinquante Nuances Plus Claires (Bande Originale du Film)",
                        "type": "album",
                        "uri": "spotify:album:3q8A9evB3WDkCXdTCG6nNt"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/5p7f24Rk5HkUZsaS3BLG5F"
                            },
                            "href": "#{api_url(conn)}/artists/5p7f24Rk5HkUZsaS3BLG5F",
                            "id": "5p7f24Rk5HkUZsaS3BLG5F",
                            "name": "Hailee Steinfeld",
                            "type": "artist",
                            "uri": "spotify:artist:5p7f24Rk5HkUZsaS3BLG5F"
                        },
                        %{
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/artist/1okJ4NC308qbtY9LyHn6DO"
                        },
                        "href": "#{api_url(conn)}/artists/1okJ4NC308qbtY9LyHn6DO",
                        "id": "1okJ4NC308qbtY9LyHn6DO",
                        "name": "BloodPop®",
                        "type": "artist",
                        "uri": "spotify:artist:1okJ4NC308qbtY9LyHn6DO"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 219373,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "USQ4E1703340"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/04rtmkmKP8MEhGS3LZBiFu"
                    },
                    "href": "#{api_url(conn)}/tracks/04rtmkmKP8MEhGS3LZBiFu",
                    "id": "04rtmkmKP8MEhGS3LZBiFu",
                    "is_playable": true,
                    "name": "Capital Letters",
                    "popularity": 66,
                    "preview_url": "https://p.scdn.co/mp3-preview/7c9bc42aa2239d48318591c90962d345aa993c72",
                    "track_number": 1,
                    "type": "track",
                    "uri": "spotify:track:04rtmkmKP8MEhGS3LZBiFu"
                },
                %{
                    "album": %{
                        "album_type": "SINGLE",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/1rclwh6bQPyiqs7SVqI4nZ"
                        },
                        "href": "#{api_url(conn)}/albums/1rclwh6bQPyiqs7SVqI4nZ",
                        "id": "1rclwh6bQPyiqs7SVqI4nZ",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/a118f002fdb34d1de48cd2386c07e3ddb6cb176a",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/9215f13ba7b41eea2cb743a1cd8a4d6de1d54bd0",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/ffb9b3217fb5d549c479d2022ddbe533778e514a",
                                "width": 64
                            }
                        ],
                        "name": "Who Mad Again",
                        "type": "album",
                        "uri": "spotify:album:1rclwh6bQPyiqs7SVqI4nZ"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/09FXva53dWku8Gu5N73rR8"
                            },
                            "href": "#{api_url(conn)}/artists/09FXva53dWku8Gu5N73rR8",
                            "id": "09FXva53dWku8Gu5N73rR8",
                            "name": "Jahyanai",
                            "type": "artist",
                            "uri": "spotify:artist:09FXva53dWku8Gu5N73rR8"
                        },
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/1fuooeJa0UywkC89lN5tl6"
                            },
                            "href": "#{api_url(conn)}/artists/1fuooeJa0UywkC89lN5tl6",
                            "id": "1fuooeJa0UywkC89lN5tl6",
                            "name": "Bamby",
                            "type": "artist",
                            "uri": "spotify:artist:1fuooeJa0UywkC89lN5tl6"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 202352,
                    "explicit": true,
                    "external_ids": %{
                        "isrc": "FR22F1703490"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/0YJnGoffpSDAmopZi2QUpw"
                    },
                    "href": "#{api_url(conn)}/tracks/0YJnGoffpSDAmopZi2QUpw",
                    "id": "0YJnGoffpSDAmopZi2QUpw",
                    "is_playable": true,
                    "name": "Who Mad Again",
                    "popularity": 69,
                    "preview_url": "https://p.scdn.co/mp3-preview/619eebcbad6c060247a0a8368fe3eafe03a80670",
                    "track_number": 1,
                    "type": "track",
                    "uri": "spotify:track:0YJnGoffpSDAmopZi2QUpw"
                },
                %{
                    "album": %{
                        "album_type": "COMPILATION",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/7ayBZIe1FHkNv0T5xFCX6F"
                        },
                        "href": "#{api_url(conn)}/albums/7ayBZIe1FHkNv0T5xFCX6F",
                        "id": "7ayBZIe1FHkNv0T5xFCX6F",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/32dbd227fc8cc94fb7ec9ab5bddc8e9ca72db125",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/4cf8ca7bf42c2ea957a27ef330a6744cda9a34e7",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/232e378bc0efb75d23df50c0bd7ee70d69e7bde3",
                                "width": 64
                            }
                        ],
                        "name": "The Greatest Showman (Original Motion Picture Soundtrack)",
                        "type": "album",
                        "uri": "spotify:album:7ayBZIe1FHkNv0T5xFCX6F"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/5F1aoppMtU3OMiltO8ymJ2"
                            },
                            "href": "#{api_url(conn)}/artists/5F1aoppMtU3OMiltO8ymJ2",
                            "id": "5F1aoppMtU3OMiltO8ymJ2",
                            "name": "Hugh Jackman",
                            "type": "artist",
                            "uri": "spotify:artist:5F1aoppMtU3OMiltO8ymJ2"
                        },
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/7HV2RI2qNug4EcQqLbCAKS"
                            },
                            "href": "#{api_url(conn)}/artists/7HV2RI2qNug4EcQqLbCAKS",
                            "id": "7HV2RI2qNug4EcQqLbCAKS",
                            "name": "Keala Settle",
                            "type": "artist",
                            "uri": "spotify:artist:7HV2RI2qNug4EcQqLbCAKS"
                        },
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/6U1dBXJhC8gXFjamvFTmHg"
                            },
                            "href": "#{api_url(conn)}/artists/6U1dBXJhC8gXFjamvFTmHg",
                            "id": "6U1dBXJhC8gXFjamvFTmHg",
                            "name": "Zac Efron",
                            "type": "artist",
                            "uri": "spotify:artist:6U1dBXJhC8gXFjamvFTmHg"
                        },
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/6sCbFbEjbYepqswM1vWjjs"
                            },
                            "href": "#{api_url(conn)}/artists/6sCbFbEjbYepqswM1vWjjs",
                            "id": "6sCbFbEjbYepqswM1vWjjs",
                            "name": "Zendaya",
                            "type": "artist",
                            "uri": "spotify:artist:6sCbFbEjbYepqswM1vWjjs"
                        },
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/63nv0hWWDob56Rk8GlNpN8"
                            },
                            "href": "#{api_url(conn)}/artists/63nv0hWWDob56Rk8GlNpN8",
                            "id": "63nv0hWWDob56Rk8GlNpN8",
                            "name": "The Greatest Showman Ensemble",
                            "type": "artist",
                            "uri": "spotify:artist:63nv0hWWDob56Rk8GlNpN8"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 302146,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "USAT21704616"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/4ylWMuGbMXNDgDd8lErEle"
                    },
                    "href": "#{api_url(conn)}/tracks/4ylWMuGbMXNDgDd8lErEle",
                    "id": "4ylWMuGbMXNDgDd8lErEle",
                    "is_playable": true,
                    "name": "The Greatest Show",
                    "popularity": 87,
                    "preview_url": "https://p.scdn.co/mp3-preview/a552ea2d2e4fa9e0429e3d5f4b15d6267d4aaf8e",
                    "track_number": 1,
                    "type": "track",
                    "uri": "spotify:track:4ylWMuGbMXNDgDd8lErEle"
                },
                %{
                    "album": %{
                        "album_type": "ALBUM",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/7AGiDF2Rd1iX80GSauaL46"
                        },
                        "href": "#{api_url(conn)}/albums/7AGiDF2Rd1iX80GSauaL46",
                        "id": "7AGiDF2Rd1iX80GSauaL46",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/5375b912a965174edc85f2e78883efa4009735e3",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/dc59ae2c91204513253aab0d40ae791c7d51a74b",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/db3e30900eca14ddbfd14bf160223b4cffa05d72",
                                "width": 64
                            }
                        ],
                        "name": "Roméo Et Juliette, Les enfants de Vérone",
                        "type": "album",
                        "uri": "spotify:album:7AGiDF2Rd1iX80GSauaL46"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/1YCF40DrzPnznumGqOl9wb"
                            },
                            "href": "#{api_url(conn)}/artists/1YCF40DrzPnznumGqOl9wb",
                            "id": "1YCF40DrzPnznumGqOl9wb",
                            "name": "Stéphane Métro",
                            "type": "artist",
                            "uri": "spotify:artist:1YCF40DrzPnznumGqOl9wb"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 220680,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "FR9W10904376"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/3q8nnXX0R2qeae0poz50A7"
                    },
                    "href": "#{api_url(conn)}/tracks/3q8nnXX0R2qeae0poz50A7",
                    "id": "3q8nnXX0R2qeae0poz50A7",
                    "is_playable": true,
                    "name": "Vérone - Roméo & Juliette, Les enfants de Vérone",
                    "popularity": 36,
                    "preview_url": "https://p.scdn.co/mp3-preview/08ec4d0d23da52d14270a292ba3cb41059ea23f7",
                    "track_number": 2,
                    "type": "track",
                    "uri": "spotify:track:3q8nnXX0R2qeae0poz50A7"
                },
                %{
                    "album": %{
                        "album_type": "ALBUM",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/3OALgjCs6Lqw41853v4wEQ"
                        },
                        "href": "#{api_url(conn)}/albums/3OALgjCs6Lqw41853v4wEQ",
                        "id": "3OALgjCs6Lqw41853v4wEQ",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/2d7d0fd071c5cc431241390af8b9f3da5294b92b",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/fef52ed085cb77b7828e8b249460480d7d45dae0",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/53aeb9e1fd32477b32bcc329bd73f35ea25c0bae",
                                "width": 64
                            }
                        ],
                        "name": "One Of The Boys",
                        "type": "album",
                        "uri": "spotify:album:3OALgjCs6Lqw41853v4wEQ"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/6jJ0s89eD6GaHleKKya26X"
                            },
                            "href": "#{api_url(conn)}/artists/6jJ0s89eD6GaHleKKya26X",
                            "id": "6jJ0s89eD6GaHleKKya26X",
                            "name": "Katy Perry",
                            "type": "artist",
                            "uri": "spotify:artist:6jJ0s89eD6GaHleKKya26X"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 220226,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "USCA20802544"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/0iGckQFyv6svOfAbAY9aWJ"
                    },
                    "href": "#{api_url(conn)}/tracks/0iGckQFyv6svOfAbAY9aWJ",
                    "id": "0iGckQFyv6svOfAbAY9aWJ",
                    "is_playable": true,
                    "name": "Hot N Cold",
                    "popularity": 67,
                    "preview_url": "https://p.scdn.co/mp3-preview/6337506b17d21a9e6e035a5c03d08fab19680cf4",
                    "track_number": 7,
                    "type": "track",
                    "uri": "spotify:track:0iGckQFyv6svOfAbAY9aWJ"
                },
                %{
                    "album": %{
                        "album_type": "COMPILATION",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/7ayBZIe1FHkNv0T5xFCX6F"
                        },
                        "href": "#{api_url(conn)}/albums/7ayBZIe1FHkNv0T5xFCX6F",
                        "id": "7ayBZIe1FHkNv0T5xFCX6F",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/32dbd227fc8cc94fb7ec9ab5bddc8e9ca72db125",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/4cf8ca7bf42c2ea957a27ef330a6744cda9a34e7",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/232e378bc0efb75d23df50c0bd7ee70d69e7bde3",
                                "width": 64
                            }
                        ],
                        "name": "The Greatest Showman (Original Motion Picture Soundtrack)",
                        "type": "album",
                        "uri": "spotify:album:7ayBZIe1FHkNv0T5xFCX6F"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/2cQr2KbzdRtIFlfbHGnNsL"
                            },
                            "href": "#{api_url(conn)}/artists/2cQr2KbzdRtIFlfbHGnNsL",
                            "id": "2cQr2KbzdRtIFlfbHGnNsL",
                            "name": "Ziv Zaifman",
                            "type": "artist",
                            "uri": "spotify:artist:2cQr2KbzdRtIFlfbHGnNsL"
                        },
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/5F1aoppMtU3OMiltO8ymJ2"
                            },
                            "href": "#{api_url(conn)}/artists/5F1aoppMtU3OMiltO8ymJ2",
                            "id": "5F1aoppMtU3OMiltO8ymJ2",
                            "name": "Hugh Jackman",
                            "type": "artist",
                            "uri": "spotify:artist:5F1aoppMtU3OMiltO8ymJ2"
                        },
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/2LAqcqAQ8KPTsl1HBgBrqM"
                            },
                            "href": "#{api_url(conn)}/artists/2LAqcqAQ8KPTsl1HBgBrqM",
                            "id": "2LAqcqAQ8KPTsl1HBgBrqM",
                            "name": "Michelle Williams",
                            "type": "artist",
                            "uri": "spotify:artist:2LAqcqAQ8KPTsl1HBgBrqM"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 269453,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "USAT21704617"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/0RoA7ObU6phWpqhlC9zH4Z"
                    },
                    "href": "#{api_url(conn)}/tracks/0RoA7ObU6phWpqhlC9zH4Z",
                    "id": "0RoA7ObU6phWpqhlC9zH4Z",
                    "is_playable": true,
                    "name": "A Million Dreams",
                    "popularity": 87,
                    "preview_url": "https://p.scdn.co/mp3-preview/e44d17b8f828c6e7e1875f4b29dde899dd6f66d4",
                    "track_number": 2,
                    "type": "track",
                    "uri": "spotify:track:0RoA7ObU6phWpqhlC9zH4Z"
                },
                %{
                    "album": %{
                        "album_type": "ALBUM",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/4vu7F6h90Br1ZtYYaqfITy"
                        },
                        "href": "#{api_url(conn)}/albums/4vu7F6h90Br1ZtYYaqfITy",
                        "id": "4vu7F6h90Br1ZtYYaqfITy",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/b48aed6518256335ebb92ef79ce9d52ac6b2955b",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/25353d0db917a2e40616425b3adeba891205ddd0",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/99c7ac13d93b5959777cc7191b40faf91e597158",
                                "width": 64
                            }
                        ],
                        "name": "The Razors Edge",
                        "type": "album",
                        "uri": "spotify:album:4vu7F6h90Br1ZtYYaqfITy"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/711MCceyCBcFnzjGY4Q7Un"
                            },
                            "href": "#{api_url(conn)}/artists/711MCceyCBcFnzjGY4Q7Un",
                            "id": "711MCceyCBcFnzjGY4Q7Un",
                            "name": "AC/DC",
                            "type": "artist",
                            "uri": "spotify:artist:711MCceyCBcFnzjGY4Q7Un"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 292880,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "AUAP09000014"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/57bgtoPSgt236HzfBOd8kj"
                    },
                    "href": "#{api_url(conn)}/tracks/57bgtoPSgt236HzfBOd8kj",
                    "id": "57bgtoPSgt236HzfBOd8kj",
                    "is_playable": true,
                    "name": "Thunderstruck",
                    "popularity": 81,
                    "preview_url": "https://p.scdn.co/mp3-preview/3885f542871846183fefbd009577c95f5f46b0af",
                    "track_number": 1,
                    "type": "track",
                    "uri": "spotify:track:57bgtoPSgt236HzfBOd8kj"
                },
                %{
                    "album": %{
                        "album_type": "ALBUM",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/77jAfTh3KH9K2reMOmTgOh"
                        },
                        "href": "#{api_url(conn)}/albums/77jAfTh3KH9K2reMOmTgOh",
                        "id": "77jAfTh3KH9K2reMOmTgOh",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/4b37c81ce1579532d39ef417141fd883357e6a6d",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/37f615e5ec794b796556f99c608b6e283dc27286",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/df67f792728252d5a9d7a99c8f090f8d6b83bcbb",
                                "width": 64
                            }
                        ],
                        "name": "This Is Acting",
                        "type": "album",
                        "uri": "spotify:album:77jAfTh3KH9K2reMOmTgOh"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/5WUlDfRSoLAfcVSX1WnrxN"
                            },
                            "href": "#{api_url(conn)}/artists/5WUlDfRSoLAfcVSX1WnrxN",
                            "id": "5WUlDfRSoLAfcVSX1WnrxN",
                            "name": "Sia",
                            "type": "artist",
                            "uri": "spotify:artist:5WUlDfRSoLAfcVSX1WnrxN"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 211666,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "USRC11502935"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/27SdWb2rFzO6GWiYDBTD9j"
                    },
                    "href": "#{api_url(conn)}/tracks/27SdWb2rFzO6GWiYDBTD9j",
                    "id": "27SdWb2rFzO6GWiYDBTD9j",
                    "is_playable": true,
                    "name": "Cheap Thrills",
                    "popularity": 80,
                    "preview_url": "https://p.scdn.co/mp3-preview/88816b2040a092aa99d5b0e42945d79dc5027c1a",
                    "track_number": 6,
                    "type": "track",
                    "uri": "spotify:track:27SdWb2rFzO6GWiYDBTD9j"
                },
                %{
                    "album": %{
                        "album_type": "ALBUM",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/3T4tUhGYeRNVUGevb0wThu"
                        },
                        "href": "#{api_url(conn)}/albums/3T4tUhGYeRNVUGevb0wThu",
                        "id": "3T4tUhGYeRNVUGevb0wThu",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/e6a84983ed9b0a04ce633b021329f7df034e7c7c",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/487bf17160e944c29ea63192a2655c0b808aee8f",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/72f9e56dae8188fc62fcdc9b081a9c11ad2d00ef",
                                "width": 64
                            }
                        ],
                        "name": "÷ (Deluxe)",
                        "type": "album",
                        "uri": "spotify:album:3T4tUhGYeRNVUGevb0wThu"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/6eUKZXaKkcviH0Ku9w2n3V"
                            },
                            "href": "#{api_url(conn)}/artists/6eUKZXaKkcviH0Ku9w2n3V",
                            "id": "6eUKZXaKkcviH0Ku9w2n3V",
                            "name": "Ed Sheeran",
                            "type": "artist",
                            "uri": "spotify:artist:6eUKZXaKkcviH0Ku9w2n3V"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 233712,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "GBAHS1600463"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/7qiZfU4dY1lWllzX7mPBI3"
                    },
                    "href": "#{api_url(conn)}/tracks/7qiZfU4dY1lWllzX7mPBI3",
                    "id": "7qiZfU4dY1lWllzX7mPBI3",
                    "is_playable": true,
                    "name": "Shape of You",
                    "popularity": 92,
                    "preview_url": "https://p.scdn.co/mp3-preview/84462d8e1e4d0f9e5ccd06f0da390f65843774a2",
                    "track_number": 4,
                    "type": "track",
                    "uri": "spotify:track:7qiZfU4dY1lWllzX7mPBI3"
                },
                %{
                    "album": %{
                        "album_type": "ALBUM",
                        "external_urls": %{
                            "spotify": "https://open.spotify.com/album/2vD3zSQr8hNlg0obNel4TE"
                        },
                        "href": "#{api_url(conn)}/albums/2vD3zSQr8hNlg0obNel4TE",
                        "id": "2vD3zSQr8hNlg0obNel4TE",
                        "images": [
                            %{
                                "height": 640,
                                "url": "https://i.scdn.co/image/8ebf0216fa9d294177e79cfef03628ed68043454",
                                "width": 640
                            },
                            %{
                                "height": 300,
                                "url": "https://i.scdn.co/image/ac7215afbceb58c8a7f3713eaf9d00ff3d959779",
                                "width": 300
                            },
                            %{
                                "height": 64,
                                "url": "https://i.scdn.co/image/014f38920ba75a4efd3488b4626cf6e16f94c9e5",
                                "width": 64
                            }
                        ],
                        "name": "Camila",
                        "type": "album",
                        "uri": "spotify:album:2vD3zSQr8hNlg0obNel4TE"
                    },
                    "artists": [
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/4nDoRrQiYLoBzwC5BhVJzF"
                            },
                            "href": "#{api_url(conn)}/artists/4nDoRrQiYLoBzwC5BhVJzF",
                            "id": "4nDoRrQiYLoBzwC5BhVJzF",
                            "name": "Camila Cabello",
                            "type": "artist",
                            "uri": "spotify:artist:4nDoRrQiYLoBzwC5BhVJzF"
                        },
                        %{
                            "external_urls": %{
                                "spotify": "https://open.spotify.com/artist/50co4Is1HCEo8bhOyUWKpn"
                            },
                            "href": "#{api_url(conn)}/artists/50co4Is1HCEo8bhOyUWKpn",
                            "id": "50co4Is1HCEo8bhOyUWKpn",
                            "name": "Young Thug",
                            "type": "artist",
                            "uri": "spotify:artist:50co4Is1HCEo8bhOyUWKpn"
                        }
                    ],
                    "disc_number": 1,
                    "duration_ms": 217306,
                    "explicit": false,
                    "external_ids": %{
                        "isrc": "USSM11706905"
                    },
                    "external_urls": %{
                        "spotify": "https://open.spotify.com/track/1rfofaqEpACxVEHIZBJe6W"
                    },
                    "href": "#{api_url(conn)}/tracks/1rfofaqEpACxVEHIZBJe6W",
                    "id": "1rfofaqEpACxVEHIZBJe6W",
                    "is_playable": true,
                    "name": "Havana",
                    "popularity": 97,
                    "preview_url": "https://p.scdn.co/mp3-preview/663b794c2fc8da8f9bbe33698cb1bac567126a23",
                    "track_number": 4,
                    "type": "track",
                    "uri": "spotify:track:1rfofaqEpACxVEHIZBJe6W"
                }
            ],
            "total": 50,
            "limit": 10,
            "offset": 0,
            "href": "#{api_url(conn)}/me/top/tracks?limit=10&offset=0&time_range=short_term",
            "previous": nil,
            "next": "#{api_url(conn)}/me/top/tracks?limit=10&offset=10&time_range=short_term"
        }
    end

    def me_playlists(conn, _params) do
        json conn, %{
            "href": "#{api_url(conn)}/users/nicoespeon/playlists?offset=0&limit=10",
            "items": [
                %{
                    "id": "7tlxsXWYH6BqzvsVSfWE98",
                    "name": "Favoris des radios",
                    "owner": %{
                        "id": "nicoespeon"
                    },
                    "snapshot_id": "RPaesGlME4xuAfhn/V8XNL1LUG7D2QtBlosY5p3gs8bfhpjmjNdQn4V5/NJsHt65",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/nicoespeon/playlists/7tlxsXWYH6BqzvsVSfWE98/tracks"
                    }
                },
                %{
                    "id": "37i9dQZEVXcGbeaIGP9BIS",
                    "name": "Découvertes de la semaine",
                    "owner": %{
                        "id": "spotify"
                    },
                    "snapshot_id": "oGYn/4o9nw3iN6WXWsV2+QplEO8vCV31UXQ/2iOgLs3nTB/TqjbbsJUxlIGuy7lvFa2j2GKvxUk=",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/spotify/playlists/37i9dQZEVXcGbeaIGP9BIS/tracks"
                    }
                },
                %{
                    "id": "56OYax7sK7HYbFQLTa1zbl",
                    "name": "Trends",
                    "owner": %{
                        "id": "nicoespeon"
                    },
                    "snapshot_id": "cFJQt8Fhm6bsF1VZnW14C9Y+ekONL8wK6G7zmoR4si+iBI97Lw2LNloQl1AeyuHD",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/nicoespeon/playlists/56OYax7sK7HYbFQLTa1zbl/tracks"
                    }
                },
                %{
                    "id": "5Yqo79lcwR6XMJcXGZeyVb",
                    "name": "On the road",
                    "owner": %{
                        "id": "nicoespeon"
                    },
                    "snapshot_id": "s5VCRZKFtwj5gdrgiuWIAkAqJXnpD1S73Dj5s6bDqbjs5NmHRP06t4MdywHITcA1",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/nicoespeon/playlists/5Yqo79lcwR6XMJcXGZeyVb/tracks"
                    }
                },
                %{
                    "id": "3pkd7H3JhY33GIN8Pune79",
                    "name": "Focus",
                    "owner": %{
                        "id": "nicoespeon"
                    },
                    "snapshot_id": "fJVg1M1cMBSu3y/gCyUD8GIw41dc8fL9PXzzI/F0SOXYy4UT5TGzO3ai/tQJGxqC",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/nicoespeon/playlists/3pkd7H3JhY33GIN8Pune79/tracks"
                    }
                },
                %{
                    "id": "0iqeL1psA8GGCxDoPMcoI9",
                    "name": "Mamour ",
                    "owner": %{
                        "id": "nicoespeon"
                    },
                    "snapshot_id": "GPMRp2PpbGbimVzJ0B/ezHiqu19U92Ef79i+z9rdUFHX5JSpCltJ2rXnabV9LpuN",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/nicoespeon/playlists/0iqeL1psA8GGCxDoPMcoI9/tracks"
                    }
                },
                %{
                    "id": "1nd6mMA3Xpz2EcrnL1A8iO",
                    "name": "Mariane ",
                    "owner": %{
                        "id": "nicoespeon"
                    },
                    "snapshot_id": "a59U/46ZRG2uYlYlgXU2p8mfcgii9Wx2VRrH/HNdT6e1Pg8917w8SlyLJj5sshf2",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/nicoespeon/playlists/1nd6mMA3Xpz2EcrnL1A8iO/tracks"
                    }
                },
                %{
                    "id": "37i9dQZF1DX39mId53VASc",
                    "name": "Motivation pour le sport",
                    "owner": %{
                        "id": "spotify"
                    },
                    "snapshot_id": "QyxVsf5XPTtFx5rlzQWguFxwbK5zVAgBjHB3EOxXNN7AwpDhd6hZazlkxiUhc8Y2TNPRE8zAxUU=",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/spotify/playlists/37i9dQZF1DX39mId53VASc/tracks"
                    }
                },
                %{
                    "id": "54ipdUgo8QOTOO3vNiVtjU",
                    "name": "Disneyland Paris Park Tunes",
                    "owner": %{
                        "id": "ipm80"
                    },
                    "snapshot_id": "OZd3q60HdcQsp0at13l9G+8vcgkXfU+LV7xYkE2RZ8erRDc6z/XljFbiTgXS93YK",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/ipm80/playlists/54ipdUgo8QOTOO3vNiVtjU/tracks"
                    }
                },
                %{
                    "id": "0NzMK83OfUk41bEGzK0Qr7",
                    "name": "The Matrix OST",
                    "owner": %{
                        "id": "1156629801"
                    },
                    "snapshot_id": "q6v86I0/0Dhy+SJJmfiITw+djZDIQGxlUEkeYeJwVpPOQfAZzn/IE7Hy7UjVmL1r",
                    "tracks": %{
                        "href": "#{api_url(conn)}/users/1156629801/playlists/0NzMK83OfUk41bEGzK0Qr7/tracks"
                    }
                }
            ],
            "limit": 10,
            "next": "#{api_url(conn)}/users/nicoespeon/playlists?offset=10&limit=10",
            "offset": 0,
            "previous": nil,
            "total": 36
        }
    end

    def user_playlist_tracks(conn, _params) do
        json conn, %{
            "items": [
                %{
                    "added_at": "2018-01-11T19:41:43Z",
                    "is_local": false,
                    "track": %{
                        "name": "Cathy Paris",
                        "uri": "spotify:track:0xBLrLM8FUlyTSLFtWrkM8"
                    }
                },
                %{
                    "added_at": "2018-01-11T19:38:08Z",
                    "is_local": false,
                    "track": %{
                        "name": "Je suis un homme",
                        "uri": "spotify:track:2rfhFgdEUIG0BNaX4BbGmA"
                    }
                },
                %{
                    "added_at": "2018-01-11T19:28:46Z",
                    "is_local": false,
                    "track": %{
                        "name": "Coincidance",
                        "uri": "spotify:track:4n8JDuLWUnkn1huTL0Y0KC"
                    }
                },
                %{
                    "added_at": "2018-01-09T21:42:33Z",
                    "is_local": false,
                    "track": %{
                        "name": "Crazy",
                        "uri": "spotify:track:3W4lY02waUaZtSwwcYgkax"
                    }
                },
                %{
                    "added_at": "2018-01-09T21:42:17Z",
                    "is_local": false,
                    "track": %{
                        "name": "Soviet Suprem Party",
                        "uri": "spotify:track:7uJ0Nzghx3EbwxkQGE3vnZ"
                    }
                },
                %{
                    "added_at": "2017-11-04T11:26:04Z",
                    "is_local": true,
                    "track": %{
                        "album": %{
                            "album_type": nil,
                            "artists": [],
                            "available_markets": [],
                            "external_urls": %{},
                            "href": nil,
                            "id": nil,
                            "images": [],
                            "name": "",
                            "release_date": nil,
                            "release_date_precision": nil,
                            "type": "album",
                            "uri": nil
                        },
                        "artists": [
                            %{
                                "external_urls": %{},
                                "href": nil,
                                "id": nil,
                                "name": "",
                                "type": "artist",
                                "uri": nil
                            }
                        ],
                        "available_markets": [],
                        "disc_number": 0,
                        "duration_ms": 292000,
                        "explicit": false,
                        "external_ids": %{},
                        "external_urls": %{},
                        "href": nil,
                        "id": nil,
                        "name": "Port Aventura - Halloween Escape",
                        "popularity": 0,
                        "preview_url": nil,
                        "track_number": 0,
                        "type": "track",
                        "uri": "spotify:local:::Port+Aventura+-+Halloween+Escape:292"
                    }
                }
            ],
            "next": nil
        }
    end

    def user_playlist_tracks_delete(conn, _params) do
        json conn, %{
            "snapshot_id": "JbtmHBDBAYu3/bt8BOXKjzKx3i0b6LCa/wVjyl6qQ2Yf6nFXkbmzuEa+ZI/U1yF+"
        }
    end
end

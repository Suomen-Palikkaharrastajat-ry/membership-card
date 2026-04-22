module Route exposing (Route(..), fromUrl)

{-| Minimal hash-based routing for the membership card SPA.
Only two meaningful routes exist: the home page and the OIDC callback.
-}

import Url exposing (Url)


type Route
    = RouteHome
    | RouteCallback
    | RouteNotFound


{-| Derive a Route from the current URL. Routing is done via the fragment (#).
-}
fromUrl : Url -> Route
fromUrl url =
    case url.fragment of
        Nothing ->
            RouteHome

        Just "" ->
            RouteHome

        Just "/" ->
            RouteHome

        Just "/callback" ->
            RouteCallback

        _ ->
            RouteNotFound

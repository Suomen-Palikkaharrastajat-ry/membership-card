module Route exposing (Route(..), fromHash)

{-| Minimal hash-based routing for the membership card SPA.
Only two meaningful routes exist: the home page and the OIDC callback.
-}


type Route
    = RouteHome
    | RouteCallback
    | RouteNotFound


{-| Parse a URL hash fragment (e.g. "#/callback") into a Route.
The hash string is provided by JS in the init flags.
-}
fromHash : String -> Route
fromHash hash =
    case hash of
        "#/callback" ->
            RouteCallback

        "" ->
            RouteHome

        "#/" ->
            RouteHome

        "#" ->
            RouteHome

        _ ->
            RouteNotFound

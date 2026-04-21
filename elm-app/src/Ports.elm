port module Ports exposing
    ( clearAuth
    , initiateLogin
    , memberInfoReceived
    , renderCard
    )

import Json.Decode as Json



-- ── Auth ports ────────────────────────────────────────────────────────────────


{-| Trigger OIDC login redirect. JS calls userManager.signinRedirect().
-}
port initiateLogin : () -> Cmd msg


{-| Clear stored MemberInfo from localStorage and sign out via Keycloak.
-}
port clearAuth : () -> Cmd msg


{-| Receive MemberInfo JSON from JS after successful OIDC sign-in or page load.
The value is a JSON object with the five JWT claim fields.
-}
port memberInfoReceived : (Json.Value -> msg) -> Sub msg



-- ── Canvas ports ──────────────────────────────────────────────────────────────


{-| Send MemberInfo to JS to draw the membership card on the canvas element.
The value is a JSON-encoded MemberInfo record.
-}
port renderCard : Json.Value -> Cmd msg

port module Ports exposing
    ( callbackParams
    , clearCallbackUrl
    , clearStoredMemberInfo
    , getCallbackParams
    , persistMemberInfo
    , startLogin
    , startLogout
    )

import Json.Encode as Encode
import Types exposing (CallbackParams, OidcConfig)



-- ── Auth ports ────────────────────────────────────────────────────────────────


{-| Start OIDC authorization code + PKCE redirect flow.
-}
port startLogin : OidcConfig -> Cmd msg


{-| Clear persisted member info from localStorage.
-}
port clearStoredMemberInfo : () -> Cmd msg


{-| Persist authenticated member info JSON to localStorage.
-}
port persistMemberInfo : Encode.Value -> Cmd msg


{-| Start OIDC end-session redirect at the identity provider.
-}
port startLogout : { authority : String, clientId : String, postLogoutRedirectUri : String } -> Cmd msg


{-| Request PKCE callback parameters stored in sessionStorage.
-}
port getCallbackParams : () -> Cmd msg


{-| Receive PKCE callback parameters (code verifier + state) from JS.
-}
port callbackParams : (CallbackParams -> msg) -> Sub msg


{-| Clear callback URL artifacts without page reload.
-}
port clearCallbackUrl : () -> Cmd msg

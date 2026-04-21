module Auth exposing
    ( decodeMemberInfo
    , restoreAuthFromFlags
    )

import Json.Decode as Json exposing (Decoder)
import Types exposing (AuthState(..), MemberInfo)



-- DECODER


{-| Decode MemberInfo from the JSON stored in localStorage.
Fields come from Keycloak JWT custom claims forwarded by oidc-client-ts.
-}
decodeMemberInfo : Decoder MemberInfo
decodeMemberInfo =
    Json.map5 MemberInfo
        (Json.field "name" Json.string)
        (Json.oneOf [ Json.field "discord" Json.string, Json.succeed "" ])
        (Json.oneOf [ Json.field "bricklink" Json.string, Json.succeed "" ])
        (Json.oneOf
            [ Json.field "registration_date" Json.string
            , Json.field "effective_date" Json.string
            , Json.succeed ""
            ]
        )
        (Json.oneOf [ Json.field "payment_date" Json.string, Json.succeed "" ])


{-| Restore auth state from the JSON string stored in localStorage.
Returns NotAuthenticated if missing or malformed.
-}
restoreAuthFromFlags : Maybe String -> AuthState
restoreAuthFromFlags maybeMemberJson =
    case maybeMemberJson of
        Just memberJson ->
            case Json.decodeString decodeMemberInfo memberJson of
                Ok info ->
                    Authenticated info

                Err _ ->
                    NotAuthenticated

        Nothing ->
            NotAuthenticated

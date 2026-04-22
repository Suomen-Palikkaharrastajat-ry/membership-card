module Auth exposing
    ( CallbackQuery
    , decodeAccessToken
    , decodeMemberInfo
    , fetchAccessToken
    , fetchUserInfo
    , parseCallbackQuery
    , restoreAuthFromFlags
    )

import Http
import Json.Decode as Json exposing (Decoder)
import String
import Types exposing (AuthState(..), MemberInfo, Msg(..), OidcConfig)
import Url


type alias CallbackQuery =
    { code : String
    , state : String
    }


{-| Decode MemberInfo from a Keycloak UserInfo response.
-}
decodeMemberInfo : Decoder MemberInfo
decodeMemberInfo =
    Json.map5 MemberInfo
        (Json.oneOf [ Json.field "name" Json.string, Json.field "preferred_username" Json.string ])
        (Json.oneOf [ Json.field "discord" Json.string, Json.succeed "" ])
        (Json.oneOf [ Json.field "bricklink" Json.string, Json.succeed "" ])
        (Json.oneOf
            [ Json.field "registration_date" Json.string
            , Json.field "registrationDate" Json.string
            , Json.field "effective_date" Json.string
            , Json.succeed ""
            ]
        )
        (Json.oneOf
            [ Json.field "payment_date" Json.string
            , Json.field "paymentDate" Json.string
            , Json.succeed ""
            ]
        )


{-| Decode access token from OIDC token endpoint response.
-}
decodeAccessToken : Decoder String
decodeAccessToken =
    Json.field "access_token" Json.string


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


{-| Parse callback query params from `Url.query` (e.g. `"code=...&state=..."`).
Returns Nothing when the query is absent or either required param is missing.
-}
parseCallbackQuery : Maybe String -> Maybe CallbackQuery
parseCallbackQuery maybeQuery =
    maybeQuery |> Maybe.andThen parseQueryString


parseQueryString : String -> Maybe CallbackQuery
parseQueryString query =
    let
        pairs =
            query
                |> String.split "&"
                |> List.filter (not << String.isEmpty)
                |> List.filterMap parsePair

        code =
            findParam "code" pairs

        state =
            findParam "state" pairs
    in
    case ( code, state ) of
        ( Just c, Just s ) ->
            Just { code = c, state = s }

        _ ->
            Nothing


fetchAccessToken : OidcConfig -> String -> String -> Cmd Msg
fetchAccessToken oidc code codeVerifier =
    Http.post
        { url = oidc.authority ++ "/protocol/openid-connect/token"
        , body =
            Http.stringBody "application/x-www-form-urlencoded"
                (buildTokenBody oidc code codeVerifier)
        , expect = Http.expectJson GotTokenResponse decodeAccessToken
        }


fetchUserInfo : String -> String -> Cmd Msg
fetchUserInfo authority accessToken =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ accessToken) ]
        , url = authority ++ "/protocol/openid-connect/userinfo"
        , body = Http.emptyBody
        , expect = Http.expectJson GotUserInfoResponse decodeMemberInfo
        , timeout = Nothing
        , tracker = Nothing
        }


buildTokenBody : OidcConfig -> String -> String -> String
buildTokenBody oidc code codeVerifier =
    [ ( "grant_type", "authorization_code" )
    , ( "client_id", oidc.clientId )
    , ( "code", code )
    , ( "redirect_uri", oidc.redirectUri )
    , ( "code_verifier", codeVerifier )
    ]
        |> List.map (\( key, value ) -> Url.percentEncode key ++ "=" ++ Url.percentEncode value)
        |> String.join "&"


parsePair : String -> Maybe ( String, String )
parsePair raw =
    case String.split "=" raw of
        [ key, value ] ->
            Just ( decodeQueryComponent key, decodeQueryComponent value )

        [ key ] ->
            Just ( decodeQueryComponent key, "" )

        _ ->
            Nothing


decodeQueryComponent : String -> String
decodeQueryComponent value =
    value
        |> String.replace "+" " "
        |> Url.percentDecode
        |> Maybe.withDefault value


findParam : String -> List ( String, String ) -> Maybe String
findParam target pairs =
    pairs
        |> List.filterMap
            (\( key, value ) ->
                if key == target && not (String.isEmpty value) then
                    Just value

                else
                    Nothing
            )
        |> List.head

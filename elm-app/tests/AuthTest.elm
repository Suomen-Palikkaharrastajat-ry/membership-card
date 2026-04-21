module AuthTest exposing (suite)

import Auth
import Expect
import Json.Decode
import Test exposing (Test, describe, test)
import Types exposing (AuthState(..))


suite : Test
suite =
    describe "Auth"
        [ describe "decodeMemberInfo"
            [ test "decodes a complete member info record" <|
                \_ ->
                    let
                        json =
                            """{"name":"Testi Käyttäjä","discord":"testi#1234","bricklink":"testikäyttäjä","registration_date":"2024-01-01","payment_date":"2024-02-15"}"""
                    in
                    case Json.Decode.decodeString Auth.decodeMemberInfo json of
                        Ok info ->
                            Expect.all
                                [ \i -> Expect.equal "Testi Käyttäjä" i.name
                                , \i -> Expect.equal "testi#1234" i.discord
                                , \i -> Expect.equal "testikäyttäjä" i.bricklink
                                , \i -> Expect.equal "2024-01-01" i.registrationDate
                                , \i -> Expect.equal "2024-02-15" i.paymentDate
                                ]
                                info

                        Err _ ->
                            Expect.fail "Expected decode to succeed"
            , test "falls back to preferred_username when name is missing" <|
                \_ ->
                    let
                        json =
                            """{"preferred_username":"fallback","payment_date":""}"""
                    in
                    case Json.Decode.decodeString Auth.decodeMemberInfo json of
                        Ok info ->
                            Expect.equal "fallback" info.name

                        Err _ ->
                            Expect.fail "Expected decode to succeed for preferred_username"
            , test "decodes with missing optional fields defaulting to empty string" <|
                \_ ->
                    let
                        json =
                            """{"name":"Vain Nimi"}"""
                    in
                    case Json.Decode.decodeString Auth.decodeMemberInfo json of
                        Ok info ->
                            Expect.all
                                [ \i -> Expect.equal "Vain Nimi" i.name
                                , \i -> Expect.equal "" i.discord
                                , \i -> Expect.equal "" i.bricklink
                                ]
                                info

                        Err _ ->
                            Expect.fail "Expected decode to succeed for partial record"
            ]
        , describe "decodeAccessToken"
            [ test "extracts access_token from token response" <|
                \_ ->
                    let
                        json =
                            """{"access_token":"abc123","expires_in":300}"""
                    in
                    case Json.Decode.decodeString Auth.decodeAccessToken json of
                        Ok token ->
                            Expect.equal "abc123" token

                        Err _ ->
                            Expect.fail "Expected access token decode to succeed"
            , test "fails when access_token is missing" <|
                \_ ->
                    case Json.Decode.decodeString Auth.decodeAccessToken "{}" of
                        Ok _ ->
                            Expect.fail "Expected decode failure"

                        Err _ ->
                            Expect.pass
            ]
        , describe "parseCallbackQuery"
            [ test "parses code and state from callback search" <|
                \_ ->
                    case Auth.parseCallbackQuery "?code=abc&state=def" of
                        Just query ->
                            Expect.all
                                [ \q -> Expect.equal "abc" q.code
                                , \q -> Expect.equal "def" q.state
                                ]
                                query

                        Nothing ->
                            Expect.fail "Expected callback query to parse"
            , test "decodes URL-encoded callback params" <|
                \_ ->
                    case Auth.parseCallbackQuery "?code=ab%2Bc%2F1&state=s%20t" of
                        Just query ->
                            Expect.all
                                [ \q -> Expect.equal "ab+c/1" q.code
                                , \q -> Expect.equal "s t" q.state
                                ]
                                query

                        Nothing ->
                            Expect.fail "Expected callback query to parse"
            , test "fails when state is missing" <|
                \_ ->
                    Expect.equal Nothing (Auth.parseCallbackQuery "?code=abc")
            ]
        , describe "restoreAuthFromFlags"
            [ test "restores Authenticated state from valid JSON string" <|
                \_ ->
                    let
                        json =
                            """{"name":"Testi","discord":"","bricklink":"","registration_date":"","payment_date":""}"""

                        result =
                            Auth.restoreAuthFromFlags (Just json)
                    in
                    case result of
                        Authenticated info ->
                            Expect.equal "Testi" info.name

                        NotAuthenticated ->
                            Expect.fail "Expected Authenticated state"
            , test "returns NotAuthenticated when memberInfo flag is Nothing" <|
                \_ ->
                    Expect.equal NotAuthenticated (Auth.restoreAuthFromFlags Nothing)
            , test "returns NotAuthenticated when JSON is malformed" <|
                \_ ->
                    Expect.equal NotAuthenticated (Auth.restoreAuthFromFlags (Just "not-json"))
            , test "returns NotAuthenticated when name fields are missing" <|
                \_ ->
                    let
                        json =
                            """{"discord":"test"}"""
                    in
                    Expect.equal NotAuthenticated (Auth.restoreAuthFromFlags (Just json))
            ]
        ]

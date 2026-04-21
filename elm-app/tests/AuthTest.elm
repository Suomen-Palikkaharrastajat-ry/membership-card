module AuthTest exposing (suite)

import Auth
import Expect
import Json.Decode
import Test exposing (Test, describe, test)
import Types exposing (AuthState(..), MemberInfo)


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
            , test "fails to decode when name is missing" <|
                \_ ->
                    let
                        json =
                            """{"discord":"test"}"""
                    in
                    case Json.Decode.decodeString Auth.decodeMemberInfo json of
                        Ok _ ->
                            Expect.fail "Expected decode to fail without name"

                        Err _ ->
                            Expect.pass
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
            , test "returns NotAuthenticated when name field is missing" <|
                \_ ->
                    let
                        json =
                            """{"discord":"test"}"""
                    in
                    Expect.equal NotAuthenticated (Auth.restoreAuthFromFlags (Just json))
            ]
        ]

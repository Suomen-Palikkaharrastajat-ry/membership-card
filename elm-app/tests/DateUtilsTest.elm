module DateUtilsTest exposing (suite)

import DateUtils
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "DateUtils"
        [ describe "parseDateParts"
            [ test "parses ISO date with optional time suffix" <|
                \_ ->
                    case DateUtils.parseDateParts "2024-02-29T12:34:56Z" of
                        Just parts ->
                            Expect.all
                                [ \p -> Expect.equal 2024 p.year
                                , \p -> Expect.equal 2 p.month
                                , \p -> Expect.equal 29 p.day
                                ]
                                parts

                        Nothing ->
                            Expect.fail "Expected ISO parse"
            , test "parses DD.MM.YYYY date" <|
                \_ ->
                    case DateUtils.parseDateParts "31.12.2025" of
                        Just parts ->
                            Expect.all
                                [ \p -> Expect.equal 2025 p.year
                                , \p -> Expect.equal 12 p.month
                                , \p -> Expect.equal 31 p.day
                                ]
                                parts

                        Nothing ->
                            Expect.fail "Expected DMY parse"
            , test "rejects invalid calendar date" <|
                \_ ->
                    Expect.equal Nothing (DateUtils.parseDateParts "2025-02-29")
            ]
        , describe "formatDateForDisplay"
            [ test "normalizes ISO date to DD.MM.YYYY" <|
                \_ ->
                    Expect.equal "01.03.2024" (DateUtils.formatDateForDisplay "2024-03-01")
            , test "preserves unknown format as-is" <|
                \_ ->
                    Expect.equal "March 5, 2024" (DateUtils.formatDateForDisplay "March 5, 2024")
            ]
        , describe "calculateExpirationDate"
            [ test "uses payment year when not paid on 31.12" <|
                \_ ->
                    Expect.equal "31.12.2027" (DateUtils.calculateExpirationDate "2027-01-15")
            , test "uses next year when paid on 31.12" <|
                \_ ->
                    Expect.equal "31.12.2028" (DateUtils.calculateExpirationDate "31.12.2027")
            , test "applies minimum validity year when date missing" <|
                \_ ->
                    Expect.equal "31.12.2026" (DateUtils.calculateExpirationDate "")
            ]
        ]

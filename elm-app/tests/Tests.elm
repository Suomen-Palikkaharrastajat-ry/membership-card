module Tests exposing (tests)

import AuthTest
import DateUtilsTest
import Test exposing (Test, describe)


tests : Test
tests =
    describe "membership-card"
        [ AuthTest.suite
        , DateUtilsTest.suite
        ]

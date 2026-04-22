module DateUtils exposing
    ( DateParts
    , calculateExpirationDate
    , formatDateForDisplay
    , parseDateParts
    )

import String


type alias DateParts =
    { year : Int
    , month : Int
    , day : Int
    }


parseDateParts : String -> Maybe DateParts
parseDateParts value =
    let
        input =
            String.trim value
    in
    if String.isEmpty input then
        Nothing

    else
        case parseIsoPrefix input of
            Just parts ->
                Just parts

            Nothing ->
                parseDayMonthYear input


formatDateForDisplay : String -> String
formatDateForDisplay value =
    case parseDateParts value of
        Just parts ->
            pad2 parts.day ++ "." ++ pad2 parts.month ++ "." ++ String.fromInt parts.year

        Nothing ->
            value


calculateExpirationDate : String -> String
calculateExpirationDate paymentDateValue =
    let
        minimumYear =
            2026
    in
    case parseDateParts paymentDateValue of
        Nothing ->
            "31.12." ++ String.fromInt minimumYear

        Just parts ->
            let
                candidateYear =
                    if parts.month == 12 && parts.day == 31 then
                        parts.year + 1

                    else
                        parts.year

                expirationYear =
                    max candidateYear minimumYear
            in
            "31.12." ++ String.fromInt expirationYear


parseIsoPrefix : String -> Maybe DateParts
parseIsoPrefix input =
    if String.length input < 10 then
        Nothing

    else
        let
            prefix =
                String.left 10 input
        in
        if String.slice 4 5 prefix /= "-" || String.slice 7 8 prefix /= "-" then
            Nothing

        else
            case
                ( String.toInt (String.slice 0 4 prefix)
                , String.toInt (String.slice 5 7 prefix)
                , String.toInt (String.slice 8 10 prefix)
                )
            of
                ( Just year, Just month, Just day ) ->
                    validateDateParts year month day

                _ ->
                    Nothing


parseDayMonthYear : String -> Maybe DateParts
parseDayMonthYear input =
    if String.length input /= 10 then
        Nothing

    else if String.slice 2 3 input /= "." || String.slice 5 6 input /= "." then
        Nothing

    else
        case
            ( String.toInt (String.slice 0 2 input)
            , String.toInt (String.slice 3 5 input)
            , String.toInt (String.slice 6 10 input)
            )
        of
            ( Just day, Just month, Just year ) ->
                validateDateParts year month day

            _ ->
                Nothing


validateDateParts : Int -> Int -> Int -> Maybe DateParts
validateDateParts year month day =
    if year < 1 || month < 1 || month > 12 || day < 1 then
        Nothing

    else
        let
            maxDay =
                daysInMonth year month
        in
        if day > maxDay then
            Nothing

        else
            Just { year = year, month = month, day = day }


daysInMonth : Int -> Int -> Int
daysInMonth year month =
    case month of
        1 ->
            31

        2 ->
            if isLeapYear year then
                29

            else
                28

        3 ->
            31

        4 ->
            30

        5 ->
            31

        6 ->
            30

        7 ->
            31

        8 ->
            31

        9 ->
            30

        10 ->
            31

        11 ->
            30

        _ ->
            31


isLeapYear : Int -> Bool
isLeapYear year =
    modBy 400 year == 0 || (modBy 4 year == 0 && modBy 100 year /= 0)


pad2 : Int -> String
pad2 value =
    if value < 10 then
        "0" ++ String.fromInt value

    else
        String.fromInt value

module CardCanvas exposing (view)

import Canvas
import Canvas.Settings exposing (fill)
import Canvas.Settings.Advanced exposing (scale, transform, translate)
import Canvas.Settings.Text as Text
import Canvas.Texture as Texture exposing (Texture)
import Color
import DateUtils
import Html exposing (Html)
import Html.Attributes exposing (class)
import String
import Types exposing (CardAssets, MemberInfo)


cardWidth : Float
cardWidth =
    640


cardHeight : Float
cardHeight =
    400


view :
    { assets : CardAssets
    , onLogoLoaded : Maybe Texture -> msg
    , onFigureLoaded : Maybe Texture -> msg
    }
    -> Float
    -> MemberInfo
    -> Html msg
view options animationMs memberInfo =
    Canvas.toHtmlWith
        { width = round cardWidth
        , height = round cardHeight
        , textures = textureSources options
        }
        [ class "membership-card-canvas" ]
        (baseRenderables animationMs
            ++ renderFigure options.assets.figure
            ++ renderLogo options.assets.logo
            ++ textRenderables memberInfo
        )


textureSources :
    { assets : CardAssets
    , onLogoLoaded : Maybe Texture -> msg
    , onFigureLoaded : Maybe Texture -> msg
    }
    -> List (Texture.Source msg)
textureSources options =
    (case options.assets.logo of
        Nothing ->
            [ Texture.loadFromImageUrl "/logo.svg" options.onLogoLoaded ]

        Just _ ->
            []
    )
        ++ (case options.assets.figure of
                Nothing ->
                    [ Texture.loadFromImageUrl "/figure.png" options.onFigureLoaded ]

                Just _ ->
                    []
           )


baseRenderables : Float -> List Canvas.Renderable
baseRenderables animationMs =
    let
        tSeconds =
            animationMs / 1000

        breathingPeriodSeconds =
            11

        breathingWave =
            sin ((2 * pi * tSeconds) / breathingPeriodSeconds)

        orbitPeriodSeconds =
            14

        orbitAngle =
            (2 * pi * tSeconds) / orbitPeriodSeconds

        yellowRadius =
            180 + (breathingWave * 6)

        blackRadius =
            185 + (breathingWave * 9)

        yellowCenterXBase =
            cardWidth + 60 - (yellowRadius / 2)

        blackCenterXBase =
            cardWidth - (blackRadius / 2)

        yellowOrbitRadius =
            4

        blackOrbitRadius =
            5

        yellowCenterX =
            yellowCenterXBase + (yellowOrbitRadius * cos orbitAngle)

        yellowCenterY =
            (cardHeight / 2) + (yellowOrbitRadius * sin orbitAngle)

        blackCenterX =
            blackCenterXBase + (blackOrbitRadius * cos (orbitAngle + (pi / 3)))

        blackCenterY =
            (cardHeight + 30) + (blackOrbitRadius * sin (orbitAngle + (pi / 3)))
    in
    [ Canvas.clear ( 0, 0 ) cardWidth cardHeight
    , Canvas.shapes [ fill white ] [ Canvas.rect ( 0, 0 ) cardWidth cardHeight ]
    , Canvas.shapes [ fill brandYellow ] [ Canvas.circle ( yellowCenterX, yellowCenterY ) yellowRadius ]
    , Canvas.shapes [ fill brandBlack ] [ Canvas.circle ( blackCenterX, blackCenterY ) blackRadius ]
    ]


renderFigure : Maybe Texture -> List Canvas.Renderable
renderFigure maybeFigure =
    case maybeFigure of
        Nothing ->
            []

        Just figure ->
            let
                dims =
                    Texture.dimensions figure

                figureHeight =
                    cardHeight - 40

                figureWidth =
                    if dims.height <= 0 then
                        0

                    else
                        (dims.width / dims.height) * figureHeight

                posX =
                    cardWidth - figureWidth - 20

                scaleX =
                    if dims.width <= 0 then
                        1

                    else
                        figureWidth / dims.width

                scaleY =
                    if dims.height <= 0 then
                        1

                    else
                        figureHeight / dims.height
            in
            [ Canvas.texture
                [ transform [ translate posX 20, scale scaleX scaleY ] ]
                ( 0, 0 )
                figure
            ]


renderLogo : Maybe Texture -> List Canvas.Renderable
renderLogo maybeLogo =
    case maybeLogo of
        Nothing ->
            []

        Just logo ->
            let
                dims =
                    Texture.dimensions logo

                logoHeight =
                    60

                logoWidth =
                    if dims.height <= 0 then
                        0

                    else
                        (dims.width / dims.height) * logoHeight

                posX =
                    28

                posY =
                    cardHeight - logoHeight - 20

                scaleX =
                    if dims.width <= 0 then
                        1

                    else
                        logoWidth / dims.width

                scaleY =
                    if dims.height <= 0 then
                        1

                    else
                        logoHeight / dims.height
            in
            [ Canvas.texture
                [ transform [ translate posX posY, scale scaleX scaleY ] ]
                ( 0, 0 )
                logo
            ]


textRenderables : MemberInfo -> List Canvas.Renderable
textRenderables memberInfo =
    let
        textX =
            36

        nameLines =
            splitName memberInfo.name

        nameLine1Y =
            148

        nameLine2Y =
            nameLine1Y + 64

        registrationDate =
            DateUtils.formatDateForDisplay memberInfo.registrationDate

        expirationDate =
            DateUtils.calculateExpirationDate memberInfo.paymentDate

        datesStartY =
            if String.isEmpty nameLines.line2 then
                nameLine2Y

            else
                nameLine2Y + 36

        registrationEntry =
            if String.isEmpty registrationDate then
                []

            else
                [ ( "Liittynyt: " ++ registrationDate, datesStartY ) ]

        lineSpacing =
            26

        expirationY =
            case registrationEntry of
                [] ->
                    datesStartY

                _ ->
                    datesStartY + lineSpacing

        expirationEntry =
            if String.isEmpty expirationDate then
                []

            else
                [ ( "Voimassa: " ++ expirationDate, expirationY ) ]

        bricklinkY =
            case List.reverse (registrationEntry ++ expirationEntry) of
                [] ->
                    datesStartY

                ( _, y ) :: _ ->
                    y + lineSpacing

        bricklinkEntry =
            if String.isEmpty memberInfo.bricklink then
                []

            else
                [ Canvas.text
                    [ fill brandBlack
                    , Text.font { size = 17, family = "Outfit500, Outfit, sans-serif" }
                    ]
                    ( textX, bricklinkY )
                    ("BrickLink: " ++ memberInfo.bricklink)
                ]

        dateRenderables =
            List.map
                (\( line, y ) ->
                    Canvas.text
                        [ fill mutedText
                        , Text.font { size = 17, family = "Outfit400, Outfit, sans-serif" }
                        ]
                        ( textX, y )
                        line
                )
                (registrationEntry ++ expirationEntry)
    in
    [ Canvas.text
        [ fill brandBlack
        , Text.font { size = 28, family = "Outfit700, Outfit, sans-serif" }
        ]
        ( textX, 52 )
        "JÄSENKORTTI"
    , Canvas.text
        [ fill brandBlack
        , Text.font { size = 32, family = "Outfit700, Outfit, sans-serif" }
        ]
        ( textX, nameLine1Y )
        nameLines.line1
    ]
        ++ (if String.isEmpty nameLines.line2 then
                []

            else
                [ Canvas.text
                    [ fill brandBlack
                    , Text.font { size = 32, family = "Outfit700, Outfit, sans-serif" }
                    ]
                    ( textX, nameLine2Y )
                    nameLines.line2
                ]
           )
        ++ dateRenderables
        ++ bricklinkEntry


splitName : String -> { line1 : String, line2 : String }
splitName name =
    let
        -- Greedy word-wrap: keep adding words to line1 until it would exceed
        -- 60% of the card width. Approximates Outfit Bold at 32pt as 19px/char.
        maxPx =
            cardWidth * 0.6

        approxPx str =
            toFloat (String.length str) * 19

        go words acc =
            case words of
                [] ->
                    { line1 = acc, line2 = "" }

                w :: rest ->
                    let
                        candidate =
                            if String.isEmpty acc then
                                w

                            else
                                acc ++ " " ++ w
                    in
                    if approxPx candidate <= maxPx || String.isEmpty acc then
                        go rest candidate

                    else
                        { line1 = acc, line2 = String.join " " (w :: rest) }
    in
    go (String.words name) ""


white : Color.Color
white =
    Color.rgb255 255 255 255


brandYellow : Color.Color
brandYellow =
    Color.rgb255 250 200 10


brandBlack : Color.Color
brandBlack =
    Color.rgb255 5 19 29


mutedText : Color.Color
mutedText =
    Color.rgb255 107 114 128

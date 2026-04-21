module Main exposing (main)

import Auth
import Browser
import CardCanvas
import Html exposing (Html, a, button, div, p, span, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import I18n
import Json.Encode as Encode
import Ports
import Route exposing (Route(..))
import String
import Types
    exposing
        ( AuthState(..)
        , CardAssets
        , Flags
        , MemberInfo
        , Model
        , Msg(..)
        , Page(..)
        )


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        authState =
            Auth.restoreAuthFromFlags flags.memberInfo

        page =
            case Route.fromHash flags.currentHash of
                RouteCallback ->
                    PageCallback

                RouteHome ->
                    PageHome

                RouteNotFound ->
                    PageNotFound

        oidc =
            { authority = flags.oidcAuthority
            , clientId = flags.oidcClientId
            , redirectUri = flags.oidcRedirectUri
            }

        initialModel =
            { page = page
            , authState = authState
            , oidc = oidc
            , currentSearch = flags.currentSearch
            , callbackError = Nothing
            , cardAssets =
                { logo = Nothing
                , figure = Nothing
                }
            }

        initCmd =
            case page of
                PageCallback ->
                    Ports.getCallbackParams ()

                _ ->
                    Cmd.none
    in
    ( initialModel, initCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoginClicked ->
            ( { model | callbackError = Nothing }
            , Ports.startLogin model.oidc
            )

        LogoutClicked ->
            ( { model | authState = NotAuthenticated, page = PageHome, callbackError = Nothing }
            , Cmd.batch
                [ Ports.clearStoredMemberInfo ()
                , Ports.startLogout
                    { authority = model.oidc.authority
                    , clientId = model.oidc.clientId
                    , postLogoutRedirectUri = logoutRedirectUri model.oidc.redirectUri
                    }
                ]
            )

        CallbackParamsReceived params ->
            case Auth.parseCallbackQuery model.currentSearch of
                Nothing ->
                    callbackFailed model

                Just query ->
                    if String.isEmpty params.codeVerifier || String.isEmpty params.state then
                        callbackFailed model

                    else if params.state /= query.state then
                        callbackFailed model

                    else
                        ( model, Auth.fetchAccessToken model.oidc query.code params.codeVerifier )

        GotTokenResponse result ->
            case result of
                Ok accessToken ->
                    ( model, Auth.fetchUserInfo model.oidc.authority accessToken )

                Err _ ->
                    callbackFailed model

        GotUserInfoResponse result ->
            case result of
                Ok info ->
                    ( { model | authState = Authenticated info, page = PageHome, callbackError = Nothing }
                    , Cmd.batch
                        [ Ports.persistMemberInfo (encodeMemberInfo info)
                        , Ports.clearCallbackUrl ()
                        ]
                    )

                Err _ ->
                    callbackFailed model

        LogoTextureLoaded maybeTexture ->
            let
                oldAssets =
                    model.cardAssets

                cardAssets =
                    { oldAssets | logo = maybeTexture }
            in
            ( { model | cardAssets = cardAssets }, Cmd.none )

        FigureTextureLoaded maybeTexture ->
            let
                oldAssets =
                    model.cardAssets

                cardAssets =
                    { oldAssets | figure = maybeTexture }
            in
            ( { model | cardAssets = cardAssets }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.callbackParams CallbackParamsReceived


view : Model -> Html Msg
view model =
    case model.page of
        PageHome ->
            viewHome model

        PageCallback ->
            viewCallback

        PageNotFound ->
            viewNotFound


viewHome : Model -> Html Msg
viewHome model =
    case model.authState of
        NotAuthenticated ->
            viewLoginPrompt model.callbackError

        Authenticated info ->
            viewCard model.cardAssets info


viewLoginPrompt : Maybe String -> Html Msg
viewLoginPrompt maybeError =
    div
        [ class "min-h-screen flex flex-col items-center justify-center gap-8 p-8" ]
        [ div [ class "flex flex-col items-center gap-2" ]
            [ span [ class "type-h2 text-text-on-dark" ] [ text I18n.pageTitle ]
            , span [ class "type-body text-text-muted" ]
                [ text "Suomen Palikkaharrastajat ry" ]
            ]
        , case maybeError of
            Just err ->
                p [ class "type-body text-brand-yellow" ] [ text err ]

            Nothing ->
                text ""
        , button
            [ class "btn-primary flex items-center gap-2 type-body px-6 py-3"
            , onClick LoginClicked
            ]
            [ text I18n.kirjaudu ]
        ]


viewCard : CardAssets -> MemberInfo -> Html Msg
viewCard assets memberInfo =
    div
        [ class "min-h-screen flex flex-col items-center justify-center gap-6 p-8" ]
        [ div [ class "card-canvas-wrapper" ]
            [ CardCanvas.view
                { assets = assets
                , onLogoLoaded = LogoTextureLoaded
                , onFigureLoaded = FigureTextureLoaded
                }
                memberInfo
            ]
        , button
            [ class "type-body-small text-text-muted hover:text-text-on-dark transition-colors"
            , onClick LogoutClicked
            ]
            [ text I18n.kirjauduUlos ]
        ]


viewCallback : Html Msg
viewCallback =
    div
        [ class "min-h-screen flex items-center justify-center" ]
        [ p [ class "type-body text-text-muted" ]
            [ text I18n.authCallbackLoading ]
        ]


viewNotFound : Html Msg
viewNotFound =
    div
        [ class "min-h-screen flex flex-col items-center justify-center gap-4" ]
        [ p [ class "type-h2 text-text-on-dark" ] [ text "404" ]
        , p [ class "type-body text-text-muted" ] [ text I18n.pageNotFound ]
        , a [ href "/", class "type-body text-brand-yellow hover:underline" ]
            [ text "← Etusivu" ]
        ]


callbackFailed : Model -> ( Model, Cmd Msg )
callbackFailed model =
    ( { model | authState = NotAuthenticated, page = PageHome, callbackError = Just I18n.authCallbackError }
    , Cmd.batch
        [ Ports.clearStoredMemberInfo ()
        , Ports.clearCallbackUrl ()
        ]
    )


logoutRedirectUri : String -> String
logoutRedirectUri redirectUri =
    if String.endsWith "#/callback" redirectUri then
        String.dropRight 10 redirectUri ++ "#/"

    else
        redirectUri


encodeMemberInfo : MemberInfo -> Encode.Value
encodeMemberInfo info =
    Encode.object
        [ ( "name", Encode.string info.name )
        , ( "discord", Encode.string info.discord )
        , ( "bricklink", Encode.string info.bricklink )
        , ( "registration_date", Encode.string info.registrationDate )
        , ( "payment_date", Encode.string info.paymentDate )
        ]

module Main exposing (main)

import Auth
import Browser
import Browser.Events
import Browser.Navigation as Nav
import CardCanvas
import FeatherIcons
import Html exposing (Html, a, button, div, p, span, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import I18n
import Json.Encode as Encode
import Ports
import Route exposing (Route(..))
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
import Url exposing (Url)


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = \model -> { title = I18n.pageTitle, body = [ view model ] }
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        authState =
            Auth.restoreAuthFromFlags flags.memberInfo

        page =
            case Route.fromUrl url of
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
            , navKey = key
            , callbackQuery = url.query
            , callbackError = Nothing
            , cardAssets =
                { logo = Nothing
                , figure = Nothing
                }
            , animationMs = 0
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

        UrlRequested (Browser.Internal url) ->
            ( model, Nav.pushUrl model.navKey (Url.toString url) )

        UrlRequested (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            let
                page =
                    case Route.fromUrl url of
                        RouteCallback ->
                            PageCallback

                        RouteHome ->
                            PageHome

                        RouteNotFound ->
                            PageNotFound
            in
            ( { model | page = page, callbackQuery = url.query }, Cmd.none )

        AnimationFrame deltaMs ->
            ( { model | animationMs = model.animationMs + deltaMs }, Cmd.none )

        CallbackParamsReceived params ->
            case Auth.parseCallbackQuery model.callbackQuery of
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
                        , Nav.replaceUrl model.navKey "/#/"
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
subscriptions model =
    let
        callbackSub =
            if model.page == PageCallback then
                Ports.callbackParams CallbackParamsReceived

            else
                Sub.none

        breathingSub =
            case ( model.page, model.authState ) of
                ( PageHome, Authenticated _ ) ->
                    Browser.Events.onAnimationFrameDelta AnimationFrame

                _ ->
                    Sub.none
    in
    Sub.batch [ callbackSub, breathingSub ]


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
            viewCard model.cardAssets model.animationMs (model.oidc.authority ++ "/account/") info


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
            [ class "btn-primary type-body px-6 py-3 whitespace-nowrap"
            , onClick LoginClicked
            ]
            [ FeatherIcons.logIn |> FeatherIcons.withSize 18 |> FeatherIcons.toHtml []
            , text I18n.kirjaudu
            ]
        ]


viewCard : CardAssets -> Float -> String -> MemberInfo -> Html Msg
viewCard assets animationMs accountUrl memberInfo =
    div
        [ class "card-page-container min-h-screen flex flex-col items-center justify-center gap-6 p-8" ]
        [ div [ class "card-rotate-wrapper" ]
            [ div [ class "card-canvas-wrapper" ]
                [ CardCanvas.view
                    { assets = assets
                    , onLogoLoaded = LogoTextureLoaded
                    , onFigureLoaded = FigureTextureLoaded
                    }
                    animationMs
                    memberInfo
                ]
            ]
        , div [ class "flex items-center gap-6" ]
            [ a
                [ href accountUrl
                , class "flex items-center gap-1 type-body-small text-text-muted hover:text-text-on-dark transition-colors"
                ]
                [ FeatherIcons.externalLink |> FeatherIcons.withSize 14 |> FeatherIcons.toHtml []
                , text I18n.paivitatietosi
                ]
            , button
                [ class "flex items-center gap-1 type-body-small text-text-muted hover:text-text-on-dark transition-colors"
                , onClick LogoutClicked
                ]
                [ FeatherIcons.logOut |> FeatherIcons.withSize 14 |> FeatherIcons.toHtml []
                , text I18n.kirjauduUlos
                ]
            ]
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
        , Nav.replaceUrl model.navKey "/#/"
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

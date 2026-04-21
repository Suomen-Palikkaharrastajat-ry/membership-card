{- Membership card application entry point.

   Pages and their purpose:

       Route         Page           Description
       ────────────  ─────────────  ──────────────────────────────────────────
       #/            PageHome       Login prompt or membership card canvas
       #/callback    PageCallback   OIDC redirect landing; JS completes sign-in
       (other)       PageNotFound   404 fallback

   Auth flow:
       1. JS reads localStorage "mc_member_info" and passes it as a flag.
       2. Elm restores AuthState from the flag via Auth.restoreAuthFromFlags.
       3. On PageHome + Authenticated: Elm sends renderCard port → JS draws canvas.
       4. Login: Elm sends initiateLogin port → JS calls userManager.signinRedirect().
       5. Callback: JS calls signinCallback(), extracts JWT claims, sends them
          via memberInfoReceived port → Elm updates auth state + sends renderCard.
       6. Logout: Elm sends clearAuth port → JS signoutRedirect + clears storage.

-}


module Main exposing (main)

import Auth
import Browser
import Html exposing (Html, a, button, canvas, div, p, span, text)
import Html.Attributes exposing (class, href, id)
import Html.Events exposing (onClick)
import I18n
import Json.Decode as Json
import Json.Encode as Encode
import Ports
import Route exposing (Route(..))
import Types
    exposing
        ( AuthState(..)
        , Flags
        , MemberInfo
        , Model
        , Msg(..)
        , Page(..)
        )



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


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

        cmd =
            case authState of
                Authenticated info ->
                    Ports.renderCard (encodeMemberInfo info)

                NotAuthenticated ->
                    Cmd.none
    in
    ( { page = page, authState = authState }, cmd )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoginClicked ->
            ( model, Ports.initiateLogin () )

        LogoutClicked ->
            ( { model | authState = NotAuthenticated }, Ports.clearAuth () )

        MemberInfoReceived value ->
            case Json.decodeValue Auth.decodeMemberInfo value of
                Ok info ->
                    ( { model | authState = Authenticated info, page = PageHome }
                    , Ports.renderCard (encodeMemberInfo info)
                    )

                Err _ ->
                    ( { model | authState = NotAuthenticated, page = PageHome }
                    , Cmd.none
                    )

        AuthCallbackDone ->
            ( { model | page = PageHome }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.memberInfoReceived MemberInfoReceived



-- VIEW


view : Model -> Html Msg
view model =
    case model.page of
        PageHome ->
            viewHome model.authState

        PageCallback ->
            viewCallback

        PageNotFound ->
            viewNotFound


viewHome : AuthState -> Html Msg
viewHome authState =
    case authState of
        NotAuthenticated ->
            viewLoginPrompt

        Authenticated _ ->
            viewCard


viewLoginPrompt : Html Msg
viewLoginPrompt =
    div
        [ class "min-h-screen flex flex-col items-center justify-center gap-8 p-8" ]
        [ div [ class "flex flex-col items-center gap-2" ]
            [ span [ class "type-h2 text-text-on-dark" ] [ text I18n.pageTitle ]
            , span [ class "type-body text-text-muted" ]
                [ text "Suomen Palikkaharrastajat ry" ]
            ]
        , button
            [ class "btn-primary flex items-center gap-2 type-body px-6 py-3"
            , onClick LoginClicked
            ]
            [ text I18n.kirjaudu ]
        ]


viewCard : Html Msg
viewCard =
    div
        [ class "min-h-screen flex flex-col items-center justify-center gap-6 p-8" ]
        [ div [ class "card-canvas-wrapper" ]
            [ canvas [ id "membership-card" ] [] ]
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



-- HELPERS


encodeMemberInfo : MemberInfo -> Json.Value
encodeMemberInfo info =
    Encode.object
        [ ( "name", Encode.string info.name )
        , ( "discord", Encode.string info.discord )
        , ( "bricklink", Encode.string info.bricklink )
        , ( "registration_date", Encode.string info.registrationDate )
        , ( "payment_date", Encode.string info.paymentDate )
        ]

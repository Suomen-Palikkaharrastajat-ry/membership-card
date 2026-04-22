module Types exposing
    ( AuthState(..)
    , CallbackParams
    , CardAssets
    , Flags
    , MemberInfo
    , Model
    , Msg(..)
    , OidcConfig
    , Page(..)
    , isAuthenticated
    )

import Browser
import Browser.Navigation as Nav
import Canvas.Texture exposing (Texture)
import Http
import Url exposing (Url)



-- FLAGS


type alias Flags =
    { memberInfo : Maybe String
    , oidcAuthority : String
    , oidcClientId : String
    , oidcRedirectUri : String
    }



-- AUTH


type AuthState
    = NotAuthenticated
    | Authenticated MemberInfo


type alias MemberInfo =
    { name : String
    , discord : String
    , bricklink : String
    , registrationDate : String
    , paymentDate : String
    }


type alias OidcConfig =
    { authority : String
    , clientId : String
    , redirectUri : String
    }


type alias CallbackParams =
    { codeVerifier : String
    , state : String
    }


isAuthenticated : AuthState -> Bool
isAuthenticated authState =
    case authState of
        Authenticated _ ->
            True

        NotAuthenticated ->
            False



-- PAGE


type Page
    = PageHome
    | PageCallback
    | PageNotFound



-- CARD ASSETS


type alias CardAssets =
    { logo : Maybe Texture
    , figure : Maybe Texture
    }



-- MODEL


type alias Model =
    { page : Page
    , authState : AuthState
    , oidc : OidcConfig
    , navKey : Nav.Key
    , callbackQuery : Maybe String
    , callbackError : Maybe String
    , cardAssets : CardAssets
    , animationMs : Float
    }



-- MSG


type Msg
    = LoginClicked
    | LogoutClicked
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | AnimationFrame Float
    | CallbackParamsReceived CallbackParams
    | GotTokenResponse (Result Http.Error String)
    | GotUserInfoResponse (Result Http.Error MemberInfo)
    | LogoTextureLoaded (Maybe Texture)
    | FigureTextureLoaded (Maybe Texture)

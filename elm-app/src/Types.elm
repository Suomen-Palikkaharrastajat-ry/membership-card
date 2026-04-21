module Types exposing
    ( AuthState(..)
    , Flags
    , MemberInfo
    , Model
    , Msg(..)
    , Page(..)
    , isAuthenticated
    )

import Json.Decode as Json



-- FLAGS


type alias Flags =
    { memberInfo : Maybe String
    , oidcAuthority : String
    , oidcClientId : String
    , oidcRedirectUri : String
    , currentHash : String
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



-- MODEL


type alias Model =
    { page : Page
    , authState : AuthState
    }



-- MSG


type Msg
    = LoginClicked
    | LogoutClicked
    | MemberInfoReceived Json.Value
    | AuthCallbackDone

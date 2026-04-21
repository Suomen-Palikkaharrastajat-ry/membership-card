module I18n exposing
    ( authCallbackError
    , authCallbackLoading
    , kirjaudu
    , kirjauduUlos
    , pageNotFound
    , pageTitle
    )


pageTitle : String
pageTitle =
    "Jäsenkortti"


kirjaudu : String
kirjaudu =
    "Kirjaudu sisään"


kirjauduUlos : String
kirjauduUlos =
    "Kirjaudu ulos"


authCallbackLoading : String
authCallbackLoading =
    "Kirjaudutaan sisään…"


authCallbackError : String
authCallbackError =
    "Kirjautuminen epäonnistui. Yritä uudelleen."


pageNotFound : String
pageNotFound =
    "Sivua ei löydy."

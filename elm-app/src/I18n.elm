module I18n exposing
    ( authCallbackError
    , authCallbackLoading
    , bricklinkLabel
    , cardTitle
    , etusivu
    , kirjaudu
    , kirjauduUlos
    , liittynytLabel
    , maksettuLabel
    , notFoundStatus
    , organizationName
    , pageNotFound
    , pageTitle
    , paivitatietosi
    , voimassaLabel
    )


pageTitle : String
pageTitle =
    "Jäsenkortti"


organizationName : String
organizationName =
    "Suomen Palikkaharrastajat ry"


cardTitle : String
cardTitle =
    "JÄSENKORTTI"


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


notFoundStatus : String
notFoundStatus =
    "404"


etusivu : String
etusivu =
    "← Etusivu"


paivitatietosi : String
paivitatietosi =
    "Päivitä tietosi"


liittynytLabel : String
liittynytLabel =
    "Liittynyt: "


maksettuLabel : String
maksettuLabel =
    "Jäsenmaksu: "


voimassaLabel : String
voimassaLabel =
    "Voimassa: "


bricklinkLabel : String
bricklinkLabel =
    "BrickLink: "

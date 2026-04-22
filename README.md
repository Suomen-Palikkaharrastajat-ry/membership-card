# Membership Card SPA

Elm SPA for displaying a digital membership card.

## Stack

- Elm 0.19.1
- Vite
- Tailwind CSS v4
- Keycloak OIDC (authorization code + PKCE)
- `joakin/elm-canvas` for card rendering

## OIDC Configuration

Set these in `.env` at the repository root:

```env
VITE_OIDC_AUTHORITY=https://your-oidc-provider.com/auth/realms/your-realm
VITE_OIDC_CLIENT_ID=your-client-id
VITE_OIDC_REDIRECT_URI=http://localhost:5173/#/callback
```

## Development

```bash
make develop
make elm-dev
```

## Build and Test

```bash
make elm-test
make elm-build
```

Build output goes to `build/`.

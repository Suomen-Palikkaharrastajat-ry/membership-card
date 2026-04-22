# AGENTS.md — membership-card

Elm SPA for displaying a digital membership card. Authenticates via Keycloak OIDC with Elm-managed token/userinfo HTTP flow and a thin JS bridge for PKCE/browser APIs. Renders the card with `joakin/elm-canvas`.

**Stack:** Elm 0.19.1 + Vite + Tailwind CSS v4 + `joakin/elm-canvas` + minimal JS ports

## Repository Layout

```
elm-app/
  src/
    Main.elm        Browser.element entry point — init/update/view/subscriptions
    Auth.elm        callback query parsing, token/userinfo HTTP, member decoder
    Types.elm       Flags, OIDC config, AuthState, MemberInfo, Model, Msg, Page
    Ports.elm       port declarations (startLogin, getCallbackParams, persistMemberInfo, startLogout, ...)
    Route.elm       Hash-based route detection (Home vs Callback)
    I18n.elm        Finnish UI strings
    DateUtils.elm   Date parsing/formatting/expiration helpers
    CardCanvas.elm  Membership card rendering via elm-canvas
  tests/
    AuthTest.elm    Unit tests for Auth module
  public/
    logo.svg        Brand logo (drawn onto canvas)
    figure.png      Decorative figure (drawn onto canvas)
    fonts/
      Outfit-VariableFont_wght.ttf   Variable font (wght 100–900)
      outfit.css                     @font-face declaration
  main.js           Thin JS bridge for PKCE redirect, storage, and logout redirect
  main.css          Tailwind v4 + full design token @theme
  index.html        HTML shell
  elm.json          Elm dependencies
  package.json      Node dependencies (vite, elm-canvas runtime)
  vite.config.js    Vite config (publicDir: public, outDir: ../build)
vendor/design-guide/   Git submodule — design-guide component library
```

## Development Environment

Uses **devenv** (Nix). Bootstrap with:

```sh
make develop   # creates devenv.local.* + opens VS Code
```

Or use the devcontainer (`.devcontainer.json` at project root).

## Build Commands

Run from the repo root (all commands delegate to `elm-app/` via pnpm):

| Command | Description |
|---------|-------------|
| `make elm-dev` | Start Vite dev server with hot reload |
| `make elm-build` | Production build → `build/` |
| `make elm-test` | Run Elm unit tests |
| `make elm-format` | Auto-format Elm source files |
| `make dist` | Alias for `elm-build` |

Or run directly inside `elm-app/`:
```sh
pnpm dev       # dev server
pnpm build     # production build
pnpm test      # elm-test
```

## OIDC Configuration

The OIDC authority, client ID, and redirect URI are read from environment variables at build time. Set them in a `.env` file inside `elm-app/`:

```env
VITE_OIDC_AUTHORITY=https://lemur-14.cloud-iam.com/auth/realms/suomenpalikkaharrastajatry
VITE_OIDC_CLIENT_ID=d31f9cee-fbe6-4672-8085-76500eb25691
VITE_OIDC_REDIRECT_URI=https://kortti.palikkaharrastajat.fi/#/callback
```

If unset, the fallback values in `main.js` are used (suitable for local development).

## Canvas Rendering

Card rendering is handled in Elm (`CardCanvas.elm`) using `joakin/elm-canvas`.

1. Elm renders an `<elm-canvas>` custom element (provided by the `elm-canvas` npm runtime).
2. Elm loads `/logo.svg` and `/figure.png` as canvas textures.
3. Elm draws the full membership card (background, circles, images, and text).

To modify the card design, edit `elm-app/src/CardCanvas.elm`.

## Auth Flow

```
User clicks "Kirjaudu" → Elm sends `startLogin`
→ JS generates PKCE verifier/challenge and redirects to Keycloak authorize endpoint
→ Keycloak consent screen
→ Redirect to /#/callback
→ Elm requests callback params from JS (`getCallbackParams` / `callbackParams`)
→ Elm exchanges code at token endpoint, then fetches `/userinfo`
→ Elm persists MemberInfo via `persistMemberInfo`
→ Elm updates model and renders card in `CardCanvas.elm`
```

Logout: Elm sends `clearStoredMemberInfo` + `startLogout` → JS clears storage and redirects to Keycloak end-session endpoint.

## Design System

This project follows the **Suomen Palikkaharrastajat ry** brand standards defined in `design-guide/`.

Key rules:
- **Never hard-code hex colour values** — use semantic Tailwind classes (`bg-brand`, `text-text-muted`, `bg-bg-dark`, etc.)
- **Named type scale** — use `.type-h1` through `.type-overline`; never raw `text-xl font-bold`
- **Font** — Outfit variable font (wght 100–900), self-hosted from `elm-app/public/fonts/`
- **Canvas exception** — `CardCanvas.elm` uses literal colour/font values to match the brand card artwork. Use canonical brand colours: `#05131D` (brand black) and `#FAC80A` (brand yellow). Do **not** use `#F2CD37`.
- **Focus rings** — `focus-visible:ring-2 focus-visible:ring-brand` (keyboard-only)
- **Reduced-motion** — animations wrapped in `@media (prefers-reduced-motion: no-preference)`
- **Component library** — `vendor/design-guide/src/Component/` has 32 reusable Elm `Html msg` components

## Commit Convention

Follow Conventional Commits (`feat`, `fix`, `refactor`, `style`, `docs`, `chore`).
Agent-authored commits must include:
```
Co-Authored-By: Claude <noreply@anthropic.com>
```

# AGENTS.md — membership-card

Elm SPA for displaying a digital membership card. Authenticates via Keycloak OIDC (using `oidc-client-ts` on the JS side) and renders the card onto an HTML5 Canvas element through Elm ports.

**Stack:** Elm 0.19.1 + Vite + Tailwind CSS v4 + `oidc-client-ts` (JS only)

## Repository Layout

```
elm-app/
  src/
    Main.elm        Browser.element entry point — init/update/view/subscriptions
    Auth.elm        restoreAuthFromFlags, decodeMemberInfo (JWT claims decoder)
    Types.elm       AuthState, MemberInfo, Model, Msg, Page
    Ports.elm       port declarations (initiateLogin, clearAuth, memberInfoReceived, renderCard)
    Route.elm       Hash-based route detection (Home vs Callback)
    I18n.elm        Finnish UI strings
  tests/
    AuthTest.elm    Unit tests for Auth module
  public/
    logo.svg        Brand logo (drawn onto canvas)
    figure.png      Decorative figure (drawn onto canvas)
    fonts/
      Outfit-VariableFont_wght.ttf   Variable font (wght 100–900)
      outfit.css                     @font-face declaration
  main.js           OIDC flow + canvas rendering (ports implementation)
  main.css          Tailwind v4 + full design token @theme
  index.html        HTML shell
  elm.json          Elm dependencies
  package.json      Node dependencies (vite, oidc-client-ts)
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

## Canvas Port Pattern

Elm has no native canvas API. The draw logic lives entirely in `main.js`:

1. Elm renders `<canvas id="membership-card">` into the DOM.
2. Elm sends `Ports.renderCard` with encoded `MemberInfo`.
3. `main.js` receives the port message, resolves the canvas element, waits for fonts + images, then calls `drawCard()`.
4. A `ResizeObserver` re-triggers `drawCard()` on viewport resize.

To modify the card's visual design, edit the `drawCard()` function in `main.js`.

## Auth Flow

```
User clicks "Kirjaudu" → Elm sends initiateLogin port
→ JS calls userManager.signinRedirect()
→ Keycloak consent screen
→ Redirect to /#/callback
→ JS calls signinCallback(), extracts JWT claims
→ Saves MemberInfo JSON to localStorage "mc_member_info"
→ Sends memberInfoReceived port to Elm
→ Elm updates model + sends renderCard port
→ JS draws canvas
```

Logout: Elm sends `clearAuth` → JS clears localStorage + calls `signoutRedirect()`.

## Design System

This project follows the **Suomen Palikkaharrastajat ry** brand standards defined in `design-guide/`.

Key rules:
- **Never hard-code hex colour values** — use semantic Tailwind classes (`bg-brand`, `text-text-muted`, `bg-bg-dark`, etc.)
- **Named type scale** — use `.type-h1` through `.type-overline`; never raw `text-xl font-bold`
- **Font** — Outfit variable font (wght 100–900), self-hosted from `elm-app/public/fonts/`
- **Canvas exception** — the canvas draw code in `main.js` uses literal hex values and font strings because the Canvas 2D API does not support CSS custom properties. Use the canonical brand colours: `#05131D` (brand black) and `#FAC80A` (brand yellow). Do **not** use `#F2CD37`.
- **Focus rings** — `focus-visible:ring-2 focus-visible:ring-brand` (keyboard-only)
- **Reduced-motion** — animations wrapped in `@media (prefers-reduced-motion: no-preference)`
- **Component library** — `vendor/design-guide/src/Component/` has 32 reusable Elm `Html msg` components

## Commit Convention

Follow Conventional Commits (`feat`, `fix`, `refactor`, `style`, `docs`, `chore`).
Agent-authored commits must include:
```
Co-Authored-By: Claude <noreply@anthropic.com>
```

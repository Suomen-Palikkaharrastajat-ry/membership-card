import './main.css'
import 'elm-canvas/elm-canvas.js'
import { Elm } from './src/Main.elm'

// ── OIDC configuration ────────────────────────────────────────────────────────

const oidcAuthority =
  import.meta.env.VITE_OIDC_AUTHORITY ||
  'https://lemur-14.cloud-iam.com/auth/realms/suomenpalikkaharrastajatry'

const oidcClientId =
  import.meta.env.VITE_OIDC_CLIENT_ID || 'd31f9cee-fbe6-4672-8085-76500eb25691'

const oidcRedirectUri =
  import.meta.env.VITE_OIDC_REDIRECT_URI || `${window.location.origin}/#/callback`

// ── App init ──────────────────────────────────────────────────────────────────

const storedMemberInfo = localStorage.getItem('mc_member_info') || null

const app = Elm.Main.init({
  flags: {
    memberInfo: storedMemberInfo,
    oidcAuthority,
    oidcClientId,
    oidcRedirectUri,
  },
})

// ── Auth ports ────────────────────────────────────────────────────────────────

app.ports.startLogin.subscribe(async ({ authority, clientId, redirectUri }) => {
  try {
    const state = randomUrlSafeString(32)
    const codeVerifier = randomUrlSafeString(64)
    const codeChallenge = await createCodeChallenge(codeVerifier)

    sessionStorage.setItem('mc_code_verifier', codeVerifier)
    sessionStorage.setItem('mc_provider_state', state)

    const authorizeUrl = new URL(`${authority}/protocol/openid-connect/auth`)
    authorizeUrl.searchParams.set('client_id', clientId)
    authorizeUrl.searchParams.set('redirect_uri', redirectUri)
    authorizeUrl.searchParams.set('response_type', 'code')
    authorizeUrl.searchParams.set('scope', 'openid profile email')
    authorizeUrl.searchParams.set('state', state)
    authorizeUrl.searchParams.set('code_challenge', codeChallenge)
    authorizeUrl.searchParams.set('code_challenge_method', 'S256')

    window.location.assign(authorizeUrl.toString())
  } catch (err) {
    console.error('OIDC startLogin failed:', err)
  }
})

// Read PKCE params and immediately clear them so they can't be replayed.
app.ports.getCallbackParams.subscribe(() => {
  const codeVerifier = sessionStorage.getItem('mc_code_verifier') || ''
  const state = sessionStorage.getItem('mc_provider_state') || ''
  sessionStorage.removeItem('mc_code_verifier')
  sessionStorage.removeItem('mc_provider_state')
  app.ports.callbackParams.send({ codeVerifier, state })
})

app.ports.persistMemberInfo.subscribe((memberInfoJson) => {
  localStorage.setItem('mc_member_info', JSON.stringify(memberInfoJson))
})

app.ports.clearStoredMemberInfo.subscribe(() => {
  localStorage.removeItem('mc_member_info')
})

app.ports.startLogout.subscribe(({ authority, clientId, postLogoutRedirectUri }) => {
  localStorage.removeItem('mc_member_info')
  sessionStorage.removeItem('mc_code_verifier')
  sessionStorage.removeItem('mc_provider_state')

  try {
    const logoutUrl = new URL(`${authority}/protocol/openid-connect/logout`)
    logoutUrl.searchParams.set('client_id', clientId)
    logoutUrl.searchParams.set('post_logout_redirect_uri', postLogoutRedirectUri)
    window.location.assign(logoutUrl.toString())
  } catch (err) {
    console.error('OIDC logout redirect failed:', err)
    window.location.assign('/')
  }
})

// ── PKCE helpers ──────────────────────────────────────────────────────────────

function randomUrlSafeString(byteLength) {
  const bytes = new Uint8Array(byteLength)
  crypto.getRandomValues(bytes)
  return toBase64Url(bytes)
}

async function createCodeChallenge(codeVerifier) {
  const data = new TextEncoder().encode(codeVerifier)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return toBase64Url(new Uint8Array(digest))
}

function toBase64Url(bytes) {
  let binary = ''
  for (let i = 0; i < bytes.length; i += 1) {
    binary += String.fromCharCode(bytes[i])
  }

  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '')
}

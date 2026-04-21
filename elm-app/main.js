import './main.css'
import { Elm } from './src/Main.elm'
import { UserManager } from 'oidc-client-ts'

// ── OIDC configuration ────────────────────────────────────────────────────────

const oidcAuthority =
  import.meta.env.VITE_OIDC_AUTHORITY ||
  'https://lemur-14.cloud-iam.com/auth/realms/suomenpalikkaharrastajatry'
const oidcClientId =
  import.meta.env.VITE_OIDC_CLIENT_ID || 'd31f9cee-fbe6-4672-8085-76500eb25691'
const oidcRedirectUri =
  import.meta.env.VITE_OIDC_REDIRECT_URI || `${window.location.origin}/#/callback`

const userManager = new UserManager({
  authority: oidcAuthority,
  client_id: oidcClientId,
  redirect_uri: oidcRedirectUri,
  response_type: 'code',
  scope: 'openid profile email',
  automaticSilentRenew: true,
})

// ── App init ──────────────────────────────────────────────────────────────────

const storedMemberInfo = localStorage.getItem('mc_member_info') || null
const currentHash = window.location.hash

const flags = {
  memberInfo: storedMemberInfo,
  oidcAuthority,
  oidcClientId,
  oidcRedirectUri,
  currentHash,
}

const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags,
})

// ── Auth ports ────────────────────────────────────────────────────────────────

app.ports.initiateLogin.subscribe(async () => {
  try {
    await userManager.signinRedirect()
  } catch (err) {
    console.error('OIDC signinRedirect failed:', err)
  }
})

app.ports.clearAuth.subscribe(async () => {
  localStorage.removeItem('mc_member_info')
  try {
    await userManager.signoutRedirect()
  } catch (err) {
    // signoutRedirect navigates away; errors are typically non-fatal
    console.error('OIDC signoutRedirect failed:', err)
  }
})

// ── OIDC callback handling ────────────────────────────────────────────────────

// If the page loaded at the callback route, complete the sign-in flow.
if (currentHash.startsWith('#/callback')) {
  ;(async () => {
    try {
      const user = await userManager.signinCallback()
      if (user && user.profile) {
        const profile = user.profile
        const memberInfo = {
          name: profile.name || profile.preferred_username || '',
          discord: profile.discord || '',
          bricklink: profile.bricklink || '',
          registration_date: profile.registration_date || profile.effective_date || '',
          payment_date: profile.payment_date || '',
        }
        localStorage.setItem('mc_member_info', JSON.stringify(memberInfo))
        // Clear the callback hash from the URL without a page reload
        history.replaceState(null, '', '/')
        // Send member info to Elm; update triggers canvas render + page change
        app.ports.memberInfoReceived.send(memberInfo)
      } else {
        console.error('signinCallback returned no user')
        app.ports.memberInfoReceived.send(null)
      }
    } catch (err) {
      console.error('OIDC signinCallback failed:', err)
      app.ports.memberInfoReceived.send(null)
    }
  })()
}

// ── Canvas rendering port ─────────────────────────────────────────────────────

/** Card dimensions (physical pixel ratio handled at draw time) */
const CARD_WIDTH = 640
const CARD_HEIGHT = 400
const CARD_RADIUS = 24

/**
 * Draw the membership card onto the <canvas id="membership-card"> element.
 * Waits for Outfit font and both images to load before drawing.
 */
app.ports.renderCard.subscribe(async (memberInfo) => {
  // Wait for next frame so Elm has had a chance to render the canvas element
  await new Promise((resolve) => requestAnimationFrame(resolve))

  const canvas = document.getElementById('membership-card')
  if (!canvas) return

  // Set physical resolution (device pixel ratio for sharp rendering)
  const dpr = window.devicePixelRatio || 1
  canvas.width = CARD_WIDTH * dpr
  canvas.height = CARD_HEIGHT * dpr

  const ctx = canvas.getContext('2d')
  ctx.scale(dpr, dpr)

  // Wait for the Outfit font to be available before drawing text
  await document.fonts.ready

  // Load both images in parallel
  const [logo, figure] = await Promise.all([
    loadImage('/logo.svg'),
    loadImage('/figure.png'),
  ])

  drawCard(ctx, memberInfo, logo, figure)

  // Redraw on resize via ResizeObserver
  if (!canvas._resizeObserver) {
    canvas._resizeObserver = new ResizeObserver(() => {
      const dpr2 = window.devicePixelRatio || 1
      canvas.width = CARD_WIDTH * dpr2
      canvas.height = CARD_HEIGHT * dpr2
      const ctx2 = canvas.getContext('2d')
      ctx2.scale(dpr2, dpr2)
      drawCard(ctx2, memberInfo, logo, figure)
    })
    canvas._resizeObserver.observe(canvas)
  }
})

/** Load an image from a URL and return a Promise<HTMLImageElement>. */
function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve(img)
    img.onerror = reject
    img.src = src
  })
}

/**
 * Render the full membership card onto the 2D canvas context.
 * Matches the layout from the original MembershipCardCanvas.svelte.
 */
function drawCard(ctx, memberInfo, logo, figure) {
  const w = CARD_WIDTH
  const h = CARD_HEIGHT
  const r = CARD_RADIUS

  // ── Background: rounded white rectangle ──────────────────────────────────
  ctx.clearRect(0, 0, w, h)
  roundRect(ctx, 0, 0, w, h, r)
  ctx.fillStyle = '#FFFFFF'
  ctx.fill()

  // ── Decorative circles ────────────────────────────────────────────────────
  // Right: brand yellow
  ctx.beginPath()
  ctx.arc(w + 60, h / 2, 180, 0, Math.PI * 2)
  ctx.fillStyle = '#FAC80A'
  ctx.fill()

  // Bottom-right: brand black (behind figure, overlapping yellow circle)
  ctx.beginPath()
  ctx.arc(w + 40, h + 70, 130, 0, Math.PI * 2)
  ctx.fillStyle = '#05131D'
  ctx.fill()

  // Re-clip to card bounds so circles don't bleed outside
  roundRect(ctx, 0, 0, w, h, r)
  ctx.clip()

  // ── Figure image (right side) ─────────────────────────────────────────────
  const figureMarginY = 20
  const figureH = h - figureMarginY * 2
  const figureW = (figure.naturalWidth / figure.naturalHeight) * figureH
  ctx.drawImage(figure, w - figureW - 20, figureMarginY, figureW, figureH)

  // ── Logo (lower-left) ─────────────────────────────────────────────────────
  const logoH = 52
  const logoW = (logo.naturalWidth / logo.naturalHeight) * logoH
  ctx.drawImage(logo, 28, h - logoH - 20, logoW, logoH)

  // ── Text ──────────────────────────────────────────────────────────────────
  const textX = 36
  let textY = 52

  // "JÄSENKORTTI" header
  ctx.fillStyle = '#05131D'
  ctx.font = '700 1.5rem "Outfit", sans-serif'
  ctx.fillText('JÄSENKORTTI', textX, textY)
  textY += 8

  // Member name — split on first two words for multi-line layout
  const nameParts = (memberInfo.name || '').split(' ')
  const nameLine1 = nameParts.slice(0, 2).join(' ')
  const nameLine2 = nameParts.slice(2).join(' ')

  ctx.font = '700 2rem "Outfit", sans-serif'
  ctx.fillStyle = '#05131D'
  textY += 44
  ctx.fillText(nameLine1, textX, textY)
  if (nameLine2) {
    textY += 36
    ctx.fillText(nameLine2, textX, textY)
  }

  // Dates
  const registrationDate = formatDateForDisplay(memberInfo.registration_date)
  const expirationDate = calculateExpirationDate(memberInfo.payment_date)

  ctx.font = '400 0.875rem "Outfit", sans-serif'
  ctx.fillStyle = '#6B7280'
  textY += 36
  if (registrationDate) {
    ctx.fillText(`Jäsen alkaen: ${registrationDate}`, textX, textY)
    textY += 22
  }
  if (expirationDate) {
    ctx.fillText(`Voimassa: ${expirationDate}`, textX, textY)
    textY += 22
  }

  // BrickLink username
  if (memberInfo.bricklink) {
    ctx.font = '500 0.875rem "Outfit", sans-serif'
    ctx.fillStyle = '#05131D'
    ctx.fillText(`BrickLink: ${memberInfo.bricklink}`, textX, textY)
  }
}

/**
 * Parse date strings in either YYYY-MM-DD (optionally with time suffix) or
 * DD.MM.YYYY format. Returns null if parsing fails.
 */
function parseDateParts(value) {
  if (typeof value !== 'string') return null
  const input = value.trim()
  if (!input) return null

  let match = input.match(/^(\d{4})-(\d{2})-(\d{2})/)
  if (match) {
    const year = Number(match[1])
    const month = Number(match[2])
    const day = Number(match[3])
    if (isValidDateParts(year, month, day)) return { year, month, day }
  }

  match = input.match(/^(\d{2})\.(\d{2})\.(\d{4})$/)
  if (match) {
    const day = Number(match[1])
    const month = Number(match[2])
    const year = Number(match[3])
    if (isValidDateParts(year, month, day)) return { year, month, day }
  }

  return null
}

/** Validate that a YYYY-MM-DD triple is a real calendar date. */
function isValidDateParts(year, month, day) {
  const date = new Date(Date.UTC(year, month - 1, day))
  return (
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day
  )
}

function pad2(value) {
  return String(value).padStart(2, '0')
}

/** Normalize date rendering to DD.MM.YYYY when a known format is provided. */
function formatDateForDisplay(value) {
  const parts = parseDateParts(value)
  if (!parts) return value || ''
  return `${pad2(parts.day)}.${pad2(parts.month)}.${parts.year}`
}

/**
 * Membership expiry is the next 31.12 after the payment date,
 * with a minimum validity end date of 31.12.2026.
 */
function calculateExpirationDate(paymentDateValue) {
  const minimumYear = 2026
  const parts = parseDateParts(paymentDateValue)

  if (!parts) return `31.12.${minimumYear}`

  const isOnDecember31 = parts.month === 12 && parts.day === 31
  const candidateYear = isOnDecember31 ? parts.year + 1 : parts.year
  const expirationYear = Math.max(candidateYear, minimumYear)

  return `31.12.${expirationYear}`
}

/**
 * Draw a rounded rectangle path (does not fill or stroke — caller does that).
 */
function roundRect(ctx, x, y, width, height, radius) {
  ctx.beginPath()
  ctx.moveTo(x + radius, y)
  ctx.lineTo(x + width - radius, y)
  ctx.quadraticCurveTo(x + width, y, x + width, y + radius)
  ctx.lineTo(x + width, y + height - radius)
  ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height)
  ctx.lineTo(x + radius, y + height)
  ctx.quadraticCurveTo(x, y + height, x, y + height - radius)
  ctx.lineTo(x, y + radius)
  ctx.quadraticCurveTo(x, y, x + radius, y)
  ctx.closePath()
}

# Mirrored code

`index.html` (Planning Poker) and `retro.html` (Retrospective) are sibling SPAs.
Both connect via MQTT.js to the same broker, share the same `clientId` /
`pp.name` / `pp.role` / `pp.broker` storage keys, and apply the same
presence / moderator / host-claim conventions.

The two files don't share a JS module — instead, the lower-level plumbing is
**copied** between them. This keeps the build-step-free, single-file SPA
property (which `stats.html` already established as the project convention).

## Machine-checked regions

Two CSS regions are delimited by sentinel comments and must be **identical in all
three files** — `index.html`, `retro.html` *and* `stats.html`:

| Sentinel | Contents |
|---|---|
| `VO THEME BOOT START` … `VO THEME BOOT END` | the `<head>` script that applies the stored theme before first paint and wires the toggle |
| `VO THEME START` … `VO THEME END` | the `:root` token block (VO base palette + poker alias layer), both dark blocks, and the `prefers-reduced-motion` guard |
| `VO CHROME START` … `VO CHROME END` | body base, focus rules, the VO header shell (`header`, `.header-content`, `.header-title`, `.header-context`, `header h1`), links, `.broker-label`, `.theme-toggle` |

Run `./check-theme-drift.ps1` before committing; it fails if the regions differ.
Line endings are normalised in the comparison (`index.html` is CRLF, the other two
are LF — pre-existing and not worth a repo-wide rewrite).

Everything outside the sentinels is still mirrored by hand.

## Sections that must stay in sync

When you change any of these in `index.html`, mirror the change to `retro.html`:

| Concept | index.html (approx) | retro.html (approx) |
|---|---|---|
| Header chrome (`.conn`, `.sound-toggle`, `.help-toggle`, `.ghost-link`) | 207-290 | inside `<style>` |
| Help-overlay styling | 275-345 | inside `<style>` |
| Form / button / panel base styles + `.btn-secondary` / `.btn-danger` | 346-420 | inside `<style>` |
| Confetti CSS + `VO_CONFETTI` + `launchConfetti` | see below | see below |
| `VO_AVATARS` / `avatarColors` (also in `stats.html`) | "Avatar helpers" | "Avatar helpers" |
| Constants (`TOPIC_ROOT`, `STATS_GUID`, `BROKERS`, `ROLES`, `JIRA_*`) | 1257-1283 | start of script |
| `clientId` bootstrap (sessionStorage) | 1290-1292 | start of script |
| Sound IIFE (`tone`, `tick`, `reveal`, `vote`) | 1345-1384 | "Sound" section |
| Avatar helpers (`hashString`, `avatarColors`, `initialsFor`) | 1387-1403 | "Avatar helpers" section |
| Confetti | 1421-1451 | "Confetti" section |
| `setConn` / `topic` / hash helpers | 1514-1539 | "Topics" + "Conn pill" sections |
| `effectiveHost` / `isModerator` / `iAmModerator` | 1544-1557 | "Moderator helpers" section |
| `markReady` / `updateLoadingPanel` | 1564-1589 | "Loading" section |
| Host-claim safeguard (`scheduleHostClaim`) | 1591-1617 | "Host claim safeguard" section |
| MQTT `connect()` + `announceSelf()` skeleton | 2551-2617 | "MQTT" section |
| `kicks/` / `handleKicked` | 3268-3304 | "Kick / leave" section |
| Leave handler | 3539-3556 | "Kick / leave" section |
| `beforeunload` handler | 3756-3762 | end of "Bindings" |

## Topic namespacing

Poker uses `${TOPIC_ROOT}/${roomId}/...` and stats `${STATS_ROOT}/rooms/...`.

Retro uses `${TOPIC_ROOT}/retro/${roomId}/...` and stats `${STATS_ROOT}/retros/...`.
The disjoint namespaces let the same kamer-code be used for both apps without
cross-talk.

## PR checklist

When you open a PR that touches:

- presence / moderator / host-claim / kick logic — **mirror to the other file**
- design tokens or shared CSS classes — **run `./check-theme-drift.ps1`**
- sound / confetti / avatar helpers — **mirror to the other file**
  (confetti now really is a mirror; it used to inject its own keyframe at runtime)
- broker selector / connection pill / sound toggle — **mirror to the other file**
- `clientId` bootstrap or storage keys (`pp.*`) — **mirror to the other file**

If you change *only* poker-specific (cards, voting, tickets, sessions) or
*only* retro-specific (templates, phases, items, groups, votes, actions) logic,
no mirroring needed.

## VO house style — deliberate choices

The three SPAs follow the Vlaamse Overheid house style as used in
`c:\Projects\vo\narictools` (see `assets/css/common.css` there). Some deviations
are intentional; do not "fix" them:

- **Badge weight is 700, not VO's 600.** 600 is not a shipped Flanders Art Sans
  weight, so the browser would synthesise it.
- **`.04em` letter-spacing is kept on uppercase micro-labels.** Uppercase at
  10–12px is measurably less legible without it.
- **`--t-med` is 200ms, not the VO `--transition-duration` of 150ms.** 150ms clips
  the card-flip choreography and flattens `--ease-spring`, which is the one
  playful easing we keep.
- **`--ease-spring` is retained**, scoped to the card deck and the modal pop-in.
  It never touches chrome.
- **`#f7c648` sits in the palette and is deliberately used nowhere.** As text it
  is 1.6:1 on white and as a 2px border it fails 3:1; `--warn` / `--gold` resolve
  to `--text-warning` (`#6d4c00`) instead. The only Flemish yellow on screen is
  the 3px header stripe (`--flemish`), which is decorative.
- **No `@font-face` and no font binaries.** `--font-sans` names
  `'Flanders Art Sans'` first and falls back to Segoe UI. Flanders Art Sans is a
  commissioned VO typeface without an open licence and this repo is public, so
  shipping the woff2 files would be redistribution. VO-managed machines have the
  font installed and render the real thing; everyone else gets the fallback.
  **Check both** when changing anything width-sensitive (header wrap,
  `.timer-text` `min-width`, badge widths).
- **Dark mode is ours, not VO's.** narictools is light-only, so the dark palette
  is derived: VO greys inverted, CTA blues lifted until they clear AA on a dark
  card (`#0055cc` is 2.44:1 there and unusable). Keep it AA in *both* themes.

### Theming

Three states, stored in `localStorage` under `pp.theme` alongside the other
`pp.*` keys: `system` (default), `light`, `dark`. The header button cycles
through them. `system` stores the string but sets **no** `data-theme` attribute,
so the media query takes over.

The dark declarations exist **twice**, and must stay identical:

```css
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { … } }
:root[data-theme="dark"] { … }
```

CSS cannot combine a media query and an attribute selector into one rule, so the
duplication is unavoidable; the drift check covers the whole region, so the two
copies cannot silently diverge across files — but keep them in sync *within* a
file by hand.

The `VO THEME BOOT` script lives in `<head>`, before `<style>`, on purpose: it
applies the stored choice before the first paint. Move it to the end of `<body>`
and every dark-mode user gets a white flash on load.

### Tokens that flip roles between themes

These do not simply get lighter or darker — they change which side they are on:

- `--accent-fg` flips from white to near-black, because the dark accent is a
  light blue. Anything sitting on `--accent` follows it automatically.
- `--avatar-fg` / `--avatar-tint` are **separate from** `--accent-fg` on purpose.
  `VO_AVATARS` are dark hues chosen for contrast with white, so they must not
  follow the flip. In dark mode `--avatar-tint` mixes the disc lighter (58%
  toward white) so it does not vanish against the card, and the initials go dark.
- `--danger-fg` exists because white text on the dark-mode danger fill
  (`#ff6b70`) is only 2.8:1.
- `--lion-fill` overrides the Flemish Lion's inline `fill="#333332"`, which is a
  presentation attribute and loses to any CSS rule.
- The retro column tokens (`--col-*-fill` / `--col-*-text`) are aliases on themed
  tokens, so `colColors()` returns `var(--col-green-fill)` rather than a hex. The
  MQTT payload still stores one hex per column — that stays the persisted form
  and the lookup key; only what gets painted comes from `:root`.

### Colour roles

`--border` (gray4, 1.53:1) is for dividers and table rules only. Control
boundaries — inputs, selects, `.card-btn`, ghost buttons — use `--border-control`
(gray3, 4.76:1), which is what WCAG 1.4.11 requires. Data marks in `stats.html`
use `--brand-2`, never `--accent`, so charts do not read as controls.

### Retro column colours

Column colours carry two roles and are split accordingly: `--col-fill` for
borders and underlines, `--col-text` for text. Always write both — `applyColColor()`
does. The wire format still stores a single hex; `colColors()` maps it to the pair
and `LEGACY_COLORS` rewrites pre-retheme terracotta hexes **at read time**, because
column colours live in a *retained* MQTT topic and are baked into permanent stats
shards. Removing that map turns every existing room and all history terracotta again.

## When to extract to shared modules

Extract `app.js` / `shared/*` modules and pay the build-step / module-server
cost when **any** of these is true:

1. A third HTML page is added (e.g. a shared landing).
2. A presence / moderator bug is missed in mirroring once.
3. The mirror diff between the two files exceeds ~30% of the lines that
   should be identical.

Until then: copy is cheaper than a build pipeline.

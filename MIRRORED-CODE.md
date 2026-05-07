# Mirrored code

`index.html` (Planning Poker) and `retro.html` (Retrospective) are sibling SPAs.
Both connect via MQTT.js to the same broker, share the same `clientId` /
`pp.name` / `pp.role` / `pp.broker` storage keys, and apply the same
presence / moderator / host-claim conventions.

The two files don't share a JS module — instead, the lower-level plumbing is
**copied** between them. This keeps the build-step-free, single-file SPA
property (which `stats.html` already established as the project convention).

## Sections that must stay in sync

When you change any of these in `index.html`, mirror the change to `retro.html`:

| Concept | index.html (approx) | retro.html (approx) |
|---|---|---|
| Design tokens (`:root`, dark mode, reduced motion) | 12-77 | top of `<style>` |
| Header chrome (`.conn`, `.sound-toggle`, `.help-toggle`) | 100-260 | inside `<style>` |
| Help-overlay styling | 196-267 | inside `<style>` |
| Form / button / panel base styles | 268-332 | inside `<style>` |
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
- design tokens or shared CSS classes — **mirror to the other file**
- sound / confetti / avatar helpers — **mirror to the other file**
- broker selector / connection pill / sound toggle — **mirror to the other file**
- `clientId` bootstrap or storage keys (`pp.*`) — **mirror to the other file**

If you change *only* poker-specific (cards, voting, tickets, sessions) or
*only* retro-specific (templates, phases, items, groups, votes, actions) logic,
no mirroring needed.

## When to extract to shared modules

Extract `app.js` / `shared/*` modules and pay the build-step / module-server
cost when **any** of these is true:

1. A third HTML page is added (e.g. a shared landing).
2. A presence / moderator bug is missed in mirroring once.
3. The mirror diff between the two files exceeds ~30% of the lines that
   should be identical.

Until then: copy is cheaper than a build pipeline.

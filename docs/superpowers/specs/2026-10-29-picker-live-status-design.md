# Design: Live opencode build status in the picker page

Date: 2026-10-29
Scope: `html-slides` skill — picker GUI (`picker\picker.html`), a new status drop file (`picker\status.js`), and the skill instructions (`SKILL.md`). No changes to `watcher.ps1` detection logic or the build steps themselves.

## Problem

After the user submits `selection.json` (BUILD DECK), the picker page only shows a toast ("opencode is reading selection.json"). During generation the user has zero visibility into what opencode is doing — which step it is on, whether it failed, and when the deck is ready. They want a loading screen in the picker UI that shows opencode's live status, with the finished deck one click away.

## Approach

A status drop file polled by the picker page via script-tag injection — the same mechanism the page already uses to read `dialog-result.js` (picker.html `pollHelper`, line 278). opencode (the skill) writes `picker\status.js` at each build checkpoint; the page re-reads it every ~1.5 s.

This works from a `file://` page with no server process, no port management, and no fetch/CORS issues (script tags over `file://` load local files fine; each poll uses a unique cache-busting query, as `pollHelper` already does).

## Components

### 1. `picker\status.js` (new, written by opencode)

The full contents of the file, overwritten on every checkpoint:

```js
window.__DECK_STATUS = {
  state: "running" | "waiting" | "done" | "error",
  step: "read-selection" | "extract" | "build" | "fit" | "deliver",
  message: "…",          // one human-readable line, e.g. "Building template <slug>"
  output: "…",           // absolute path to the deck — only when state === "done"
  updated_at: "<ISO>"    // when this checkpoint was written
};
```

- `state: "waiting"` — opencode has picked up selection.json but not started a specific step yet (used to flush stale status from a previous run; see Staleness).
- Steps map to SKILL.md workflow: `read-selection` (Step 1 pickup), `extract` (Step 2), `build` (Step 3), `fit` (Step 4), `deliver` (Step 5).
- Written with the agent's file-write tool (never a shell heredoc), so JSON escaping is consistent.

### 2. `picker.html` changes

After a successful submission (current `finish()`) the page swaps its main view to a **"Generating your deck" status screen**:

- **Step checklist** — five entries (Read selection → Extract content → Build template → Font fit → Deliver), each pending / spinner / done / failed according to progress.
- **Status log** — scrolling list of past checkpoints (step + message + time), most recent last.
- **States**:
  - *Waiting* — submission sent, no fresh status yet: "waiting for opencode to pick up …".
  - *Running* — checkpoint step highlights in the checklist; `message` shown.
  - *Done* — "Deck ready" with the deck filename and an **Open deck** button (`<a href="file:///…">`, from `status.output`).
  - *Error* — the failing step + `message`, in the `--bad` color.
  - *Stalled hint* — if no fresh status arrives within 2 minutes of submission, a dim hint line: "opencode hasn't picked up yet — run `picker\watcher.ps1` or ask opencode to build `picker\selection.json`".
- **Polling** — every 1.5 s re-inject `<script src="status.js?ts=…&n=Date.now()">` (mirrors `pollHelper`). `onerror` (file missing) is normal before the first checkpoint — keep polling, it is not a fatal state.
- **Rejoin on load** — on page load, poll once: if a status exists and is not resolved (running) or resolved within the last hour, show the status screen. A **"‹ back to picker"** link dismisses the overlay and returns to the template grid (pooling continues so the user can revisit). Closing the tab entirely remains safe — opencode delivers the deck by opening it in the browser as today.
- **Staleness handling**:
  1. opencode's first write every run is a `waiting`/start checkpoint, which *overwrites* any old status and flushes the previous run's tail state.
  2. The page additionally records `Date.now()` at submission and ignores statuses with `updated_at` older than that while the overlay was opened by a fresh submission in this session. Timestamps across processes come from the same machine clock; a couple of seconds' skew is absorbed by tolerance (ignore only if older than submit-time − 2 s).

### 3. `SKILL.md` changes

New short section **"Progress reporting (mandatory)"** placed before the Workflow:

- On picking up `selection.json`, first overwrite `picker\status.js` with a `waiting`/`read-selection` checkpoint (this flushes stale status).
- At every workflow step boundary (Steps 1–5) write a checkpoint with that step and a short message (e.g. `"Building template zarazhang-rui/xyz"`); a `done` write at Step 5 includes `output` (the deck's absolute path).
- On any failure, immediately write `state:"error"` with the failing step and a one-line reason — the skill must not exit silently while the user is watching a loading screen.
- Applies to both flows — the interactive session and the standalone `watcher.ps1` → `opencode run` spawn — because both execute this skill.

## Data flow

```
picker BUILD → selection.json → (watcher / opencode session picks up)
opencode: writes status.js (waiting) → extract → build → fit → deliver (done + output)
picker page: poll status.js every 1.5 s → render checklist/log → done: Open deck button
```

## Error handling

- Missing `status.js`: shown as the *Waiting* state, poll continues (script `onerror` → retry next tick).
- Malformed status.js (e.g. mid-write): parse failure surfaces as a script error — the poll checks `window.__DECK_STATUS !== null` after load and treats a failed parse like `onerror` (retry); the file is overwritten whole on every checkpoint so torn reads are transient at worst (~1 KB write).
- opencode crash without an error write: page stays in *Running* on the last checkpoint; the stalled hint (2 min without ANY status change) extends to suggest restarting the build.
- Deck path missing at `done`: render the `output` path as text and disable the Open button with a note, so the user can locate the file manually if it was moved.

## Testing

- `picker\tests\test-picker-dom.ps1` gains cases: overlay renders on simulated submission; step mapping for each `step` value; done state builds the `file://` link; error state renders; stale-status from a previous run is ignored when a submission timestamp exists.
- `picker\tests\test-watcher.ps1` — unchanged behavior asserted (watcher still exits 0 on change).
- Manual: run a real build, confirm the checklist advances and the Open deck button launches the final HTML.

## Out of scope

- Push/SSE via a local HTTP server (rejected: extra process + lifecycle).
- Showing opencode's raw CLI output/terminal dump in the page.
- Cancelling a running build from the page.

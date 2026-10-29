# Picker UI v2 — sidebar-integrated form + 3-slide modal — Design

Date: 2026-10-29
Status: Approved (pending implementation plan)
Parent spec: docs/specs/2026-10-29-picker-gui-design.md (unchanged parts still govern)

## Purpose

Rework the picker GUI layout and template preview: move the footer's form and
actions into a full-height left sidebar, remove the (classroom-irrelevant)
occasion tag filter, and preview the chosen template's first three slides in a
modal before selecting it. Vertical space reclaimed by the retired footer bar
goes to the template grid so cards stop feeling squished.

## 1 — Layout (one-time reshuffle; zero JS-logic changes)

- Left sidebar, fixed 360px, full window height, internally scrollable; one
  scroll column top-to-bottom:
  search box, Scheme / Density / Formality filter groups (Tag group removed),
  Deck options (slide count auto+number, density select), Content-files
  textarea, Notes input, divider, selected-template ribbon, library badge,
  actions row (Copy selection + BUILD DECK).
- Right: template grid occupies 100% of remaining width AND 100% vertical
  height. No bottom footer bar exists anymore.
- FORBIDDEN (unmodified behavior): payload() shape (incl. `generated_at`),
  save chain (remembered-dir → one-time showDirectoryPicker → clipboard
  fallback), path-format validation, localStorage `picker.lastTemplate`,
  IndexedDB dir handle, buildBtn gating, toast, `?from=opencode` banner
  (lives in header).

## 2 — Tag (occasion) filter removal

- Delete the rail's Tags section and all occasion branches from the JS
  (`values()` key list and `passes()`).
- `occasion` REMAINS in templates.json / library.json.js — consumed by
  opencode's nearest-match template substitution; only the UI filter goes.
- Regression test asserts `data-filter="occasion"` is ABSENT (cannot creep
  back).

## 3 — Card click → 3-slide preview modal

- Card thumbnail = `screenshots/<slug>-1.png`. Clicking a card no longer
  selects directly; it opens a modal showing that template's first three
  slides (`<slug>-1.png` ..`-3.png`).
- Modal: template name + tagline header, three screenshots (side by side,
  ~each 1/3 of modal width, equal height), dark overlay; closes via X button,
  Esc, or clicking the overlay WITHOUT selecting; SELECT button confirms the
  pick → gracefully closes, updates card ring/check + ribbon + localStorage
  like today's direct-click did.
- Keyboard: Esc = cancel (never confirm). Tab order reaches SELECT from the
  images.

## 4 — Installer: first three slides per template

- Capture output becomes `screenshots/<slug>-1.png`, `<slug>-2.png`,
  `<slug>-3.png` (first three slides of the template). `slide_count` in the
  data is always ≥ 3 for this library, but the capture loop must tolerate
  fewer slides gracefully in the pipeline (skip missing-tile errors only if
  THE SLIDE ITSELF does not exist — report otherwise).
- Method (choose at implementation by discovery, in order):
  1. If deck-stage.js navigation supports a slide hash/query that renders one
     slide at a time, drive 3 single-stage captures.
  2. Fallback: capture a full first-three-slides strip (window
     1920x(1080x3) if slides stack vertically, or 1920x1080 with
     slide-navigation JS) and crop three 1920x1080 tiles via
     System.Drawing. Discovery happens in Task order; report which path was
     real.
- Validation: per-slug, per-tile: exists AND > 20 KB; missing tiles list slug
  and tile number by name and fail the installer (unless the template itself
  has < 3 slides — then require what exists and say so).
- Migration: legacy single `screenshots/<slug>.png` files are deleted during
  a capture run (only after the slug's three new tiles validate).
- `-Force` re-captures all 102 tiles at once for the one-off migration on
  the authoring machine.
- web-browser.txt, HKCU-first chrome resolution, BOM-less writers,
  `-SkipShortcuts`, mutex behavior — all unchanged from the parent spec.

## 5 — Tests & docs

- test-screenshots.ps1: assert per slug the exact triple (or justified
  partial for < 3-sliders); each tile `> 20 KB`; legacy names absent.
- test-picker-dom.ps1: cards ≥ 30; grid rail/panel new markers; modal shell
  exists with three image slots; `data-filter="occasion"` ABSENT; BUILD
  DECK + recomputed count still render.
- test-suite total may change; every script must end exit 0.
- README repo-layout changes to `screenshots/<slug>-{1,2,3}.png`.

## 6 — Verification

- Full suite green (5 scripts).
- Installer -Force run: 102/102 tiles validated (34 x 3), skip-path stable
  on second run.
- Manual click-through (human, headless-impossible items): card click →
  modal shows 3 slides → Esc cancels unselected, SELECT confirms; sidebar
  textarea comfortable at 360px; grid not squished; save chain (silent
  second write) unaffected.

## Out of scope

- Any watcher / selection.json handoff changes; moods; non-classroom
  filters; slide 4+ previews; disk-caching of modal thumbnails.

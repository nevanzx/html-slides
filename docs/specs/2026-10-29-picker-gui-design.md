# HTML Slides Picker GUI — Design

Date: 2026-10-29
Status: Approved (pending implementation plan)

## Purpose

Replace the in-chat question flow of the `html-slides` skill with a browser GUI
("picker") that collects every input up front and hands it to opencode as a JSON
file. The user must never be asked in opencode what the GUI can decide. The picker
is also usable as a Chrome/Edge app-mode "installation" without opening opencode
first.

## Fixed assumptions (not asked, not shown)

- Occasion: always classroom discussion.
- Audience: high school (internally implied, never surfaced in UI or outputs).
- Mood: removed — the template choice covers it.
- Title slide text: derived from the source document titles.
- Special slides (agenda, Q&A, references...): AI discretion.

## File layout

```
C:\Users\aclco\.claude\skills\html-slides\
  SKILL.md                      (modified: Steps 1-4 replaced)
  picker\
    picker.html                 single file, inline CSS/JS, first paint offline
    screenshots\<slug>.png      34 title-slide captures (1920x1080 stage)
    templates.json              embedded copy of repo index.json + updated_at
    selection.json              pending selection (canonical handoff artifact)
    picker.cmd                  shortcut target; opens UI + starts watcher
    watcher.ps1                 polls selection.json, triggers opencode
    install.ps1                 one-time setup / refresh screenshots
    repo\                       `--depth 1` clone of beautiful-html-templates
```

## Selection JSON schema

```json
{
  "template": "daisy-days",
  "slide_count": 12,
  "density": "balanced",
  "content_files": ["D:\\lessons\\Week-1-Notebook.html"],
  "notes": ""
}
```

- `slide_count`: number, or the string `"auto"` (AI decides; same for `density`:
  `"auto"` | `"sparse"` | `"balanced"` | `"dense"`).
- Written only by picker.html, with UTF-8, and never deleted afterwards (it
  stays so a deck can be rebuilt).

## GUI (picker.html)

Single dark-professional window. Layout:

- Slim header: product name + templates library age badge.
- Left filter rail: scheme (light/dark/mixed), density, formality, occasion
  tags, search box; live filtered count ("12 / 34").
- Template grid: screenshot cards with name + tagline on hover; click selects
  (accent ring + check); keyboard navigable.
- Selected-template ribbon.
- Deck options row: slide count (number with an "auto" toggle), density select.
- Content source: multiline path field + "Pick" button (native file dialog,
  appends real absolute paths).
- Optional extra-notes textarea.
- Footer: "Build deck" (disabled until template selected and at least one
  existing file path; invalid path shown inline red) and "Copy selection"
  fallback (copies JSON to clipboard with an explanatory toast).

Persistence: last chosen template is highlighted when the app reopens.

Save mechanics: "Build deck" writes `selection.json` into the picker folder
using the File System Access API save dialog (Edge/Chrome), with a suggested
file name. No protocol or registry involved in either flow.

## Flow A — from an open opencode session

1. User asks opencode for HTML slides.
2. Opencode starts the UI (`Start-Process` on picker.html + `?from=opencode`)
   and polls for `selection.json` mtime/content change (same loop as
   `watcher.ps1` semantics; 60-min cap).
3. User submits in the UI; JSON is written; opencode reads it and builds.

## Flow B — standalone

1. Double-click the "HTML Slides Picker" shortcut → `picker.cmd`.
2. `picker.cmd` opens the UI app-window and starts `watcher.ps1`.
3. User submits; watcher detects the change and fires
   `opencode run "<build prompt>"` (visible in a Windows Terminal window) with
   the deterministic prompt
   "Build the html-slides deck described in selection.json. Never re-ask any
   question the JSON already answers."

No registry edits, no custom URL protocol, no clipboard games. Two windows is
all the user ever sees (a UI window + TUI terminal).

## Watcher (watcher.ps1)

- Arg: `--wait`. Polls content hash (not mtime) of selection.json every 1s.
- Soft-exits with a message after a configurable idle cap (default 60 min).
- Never consumes the file.

## Installer / maintenance (install.ps1)

1. Clone/refresh `beautiful-html-templates` into `picker\repo` (depth 1).
2. Screenshot every template's title slide with Edge headless
   (`--screenshot --window-size=1920,1080`); skip existing slugs unless
   `--force`. Report any slug that produces a missing/tiny PNG (<20 KB) by
   name and fail.
3. Regenerate `templates.json` from the repo's `index.json` (+ updated_at).
4. Install shortcuts (Desktop + Start Menu): "HTML Slides Picker" →
   `picker.cmd`. Browser resolved Edge-first from registry, then Chrome.
5. installer never deletes user data (selection.json preserved).

Re-run only when the upstream template library changes.

## SKILL.md changes

Steps 1-4 replaced:

```
Step 1 (new) — Launch picker & read selection.json
  - Interactive session: Start-Process picker.html?from=opencode, then poll
    for selection.json change (60-min cap; ask user if timed out).
  - Read the JSON. Fixed context: classroom discussion. If a required field
    is empty/invalid -> only then ask (fail-safe path).
Step 2 — Content extraction
  - Read each path in content_files; derive slide structure from the source.
    Titles come from source. Slide count/density from JSON ("auto" -> decide).
Step 3 — Build the deck in the chosen template (former Step 5)
Step 4 — Font-fit pass incl. the persistent 30px floor (former Step 6)
Step 5 — Deliver
```

Removed: cloning the repo per run, the 3-preview round-trip and wait, the
occasion/mood questions. The existing "Common Mistakes" list gains:
"Asking any question the GUI already answered; reading selection.json before
the watcher reports it changed."

## Error handling

- GUI validation is live; JSON write failure falls back to "Copy selection".
- Watcher compares content hash (immune to mtime oddities).
- Installer verifies browser registry presence, all 34 screenshots valid,
  templates.json parses.
- GUI shows `templates.json` age; opencode maps an unknown/removed template
  slug to the nearest match and states the substitution.
- All path I/O UTF-8; Windows backslash paths preserved verbatim in the JSON.

## Testing

1. JSON round-trip: submit -> read selection.json -> assert fields including
   `"auto"` semantics.
2. Watcher: fake file appearing mid-wait -> triggered <2 s; same-mtime
   overwrite detected; timeout soft-exits.
3. Screenshot pipeline: 3-slug fixture run, then full 34-slug run; every PNG
   non-blank (>20 KB).
4. Flow A end-to-end: real opencode session builds the deck with zero chat
   questions; chosen template honored; 30px floor respected.
5. Flow B end-to-end: double-click -> submit -> deck built headlessly.

## Out of scope

- Any registry/protocol integration; any server; PWA service worker over
  file://; multi-deck batching; non-classroom occasions in the UI.

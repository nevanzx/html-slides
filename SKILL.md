---
name: html-slides
description: Use when the user wants slides, a deck, or a presentation delivered as a browser HTML file with full template artwork (or names a template from beautiful-html-templates), or when the user asks to "make slides/presentation" without specifying PowerPoint vs HTML — in that case ask whether docx-to-ppt (editable PowerPoint) or html-slides (browser HTML) should handle it before starting.
---

# HTML Slides

## Overview

Build presentation decks by **fully adapting the zarazhangrui/beautiful-html-templates library**: build the chosen template from the LOCAL clone at `picker\repo` (created/refreshed by `picker\install.ps1`) — never re-clone from GitHub while the local clone exists — replace placeholder content with real content, and deliver a standalone HTML file that looks exactly like the template — fonts, palette, every decorative element. The deliverable is HTML presented in a browser; never a .pptx.

## Step 0 — Routing (mandatory)

If the user asks for "slides", "a deck", or "a presentation" without specifying the format, STOP and ask: "PowerPoint deck (docx-to-ppt) or HTML slides (html-slides)?" Proceed only after the answer. Do not infer from past projects.

## Progress reporting (mandatory)

While building — in ANY flow (this session, or a standalone `opencode run` spawned by `picker\watcher.ps1`) — overwrite `picker\status.js` (next to `picker.html`) at each checkpoint so the picker GUI's loading screen can show live progress. Overwrite the WHOLE file with the file-write tool (never a shell heredoc), as a single statement with exactly these fields:

```js
window.__DECK_STATUS = { state: "running", step: "build", message: "Building template <slug>", output: undefined, updated_at: "2026-01-01T00:00:00.000Z" };
```

- `state`: `"waiting"` (picked up selection.json, no step started yet) | `"running"` | `"done"` | `"error"`
- `step`: `read-selection` | `extract` | `build` | `fit` | `deliver` (maps to the Workflow steps)
- `message`: one short human-readable line (e.g. `Building template paper-tiger`)
- `output`: absolute path to the deck — ONLY when `state` is `"done"`
- `updated_at`: current ISO timestamp at write time

Required checkpoints:
1. **First write on pickup, before anything else:** `state:"waiting"`, `step:"read-selection"` — this overwrites any previous run's status; the page's stale-state guard depends on it.
2. **Every workflow step boundary (Steps 1–5):** update `step` + `message`.
3. **Step 5 completion:** `state:"done"`, `step:"deliver"`, `output` set to the deck's absolute path.
4. **Any failure:** IMMEDIATELY, before exiting — `state:"error"`, `step` = failing step, `message` = one-line reason. Never exit silently while the user watches the loading screen.

## Workflow

**Step 1 — Launch the picker and read selection.json.**
If the user did not already come from the picker GUI:
```powershell
$browser = (Get-Content "C:\Users\aclco\.claude\skills\html-slides\picker\web-browser.txt" -Raw).Trim()
Start-Process $browser -ArgumentList '--app=file:///C:/Users/aclco/.claude/skills/html-slides/picker/picker.html?from=opencode'
```
Wait for the watcher to report the selection — bounded retry loop, NOT one blocking hour-long call:
```powershell
$watcher = "C:\Users\aclco\.claude\skills\html-slides\picker\watcher.ps1"
$tries = 0
while ($tries -lt 5) {
    powershell -NoProfile -ExecutionPolicy Bypass -File $watcher -NotifyOnly -TimeoutSec 120
    if ($LASTEXITCODE -eq 0) { break }          # selection.json changed -> read it now
    if ($LASTEXITCODE -eq 3) { break }          # timeout, no selection -> ask the user (only allowed fallback ask)
    if ($LASTEXITCODE -eq 4) { $tries++; Start-Sleep -Seconds 2; continue }   # another watcher holds the mutex -> retry
    break                                        # unexpected exit -> ask in chat
}
```
Watcher exit codes: **0** = selection.json changed (read it), **3** = timeout cap reached with no change, **4** = another watcher instance already holds the mutex (retry shortly).
Expected schema (selection.json): `template`: slug from templates.json; `slide_count`: number or `"auto"`; `density`: `"auto"`|`"sparse"`|`"balanced"`|`"dense"`; `content_files`: array of absolute paths; `notes`: free text; `generated_at`: watcher trigger field (not consumed by the build).
Fixed context (never asked, never surfaced): occasion = classroom discussion; audience = high school; mood is irrelevant (the template choice covers it); deck titles follow the source document titles; extra slides only when content earns them. Only if a required JSON field is missing/invalid: ask — otherwise trust the JSON.

**Step 2 — Extract the content.**
For every path in `content_files`, read the source. Organize slides from the source itself: one idea per slide; headlines presentation-ready and true to the source's titles; slide count and density from the JSON (`"auto"` → your call). If a path is missing, report which file was readable/missing and continue with what resolved.

**Step 3 — Build the deck in the chosen template.**
Import: `picker\repo` (refresh with `picker\install.ps1` ONLY if `templates.json` is older than the user wants or `repo` is missing). Locate `template`'s slug in `picker\templates.json`; if mapped to a missing slug, name the nearest equivalent based on scheme/density/formality and SAY you substituted. In the chosen template: follow the repo's own `AGENTS.md` §3–§5 — preserve fonts, palette, layout grid, slide-level CSS classes, decorative elements, and the navigation runtime; replace all placeholder content; duplicate the most appropriate layout for extra slides and update page-number labels (`NN / TT`); design missing layouts with the template's own design system — same fonts, colors, decor vocabulary, spacing rhythm, component grammar, chrome.

**Step 4 — Auto font-size fit pass.** The template renders a fixed 1920×1080 stage that the browser scales uniformly (it may letterbox or pillarbox; content never reflows). After building every slide:
1. Check each slide for overflow — content clipped, text running past cards/columns, elements colliding with decor or the page-number chrome.
2. Fix overflow WITHOUT restructuring the design: step font sizes down within the template's type scale (keep relative hierarchy, e.g. 32→28→24 px), tighten line-height or card padding, or shorten copy. Never move the stage scale itself.
3. Re-space on the smallest display you expect (13-inch laptop) and confirm nothing clips on the largest (4K) — the uniform scale should handle both once the stage is clean at 1920×1080.
4. If a slide still overflows, split it into two slides instead of shrinking further.

**USER RULE (persistent, overrides the ~14px default in point 4 of the original font-fit pass):** every deck built for this user must keep a **30px minimum font size for every text element** at the 1920×1080 stage — body copy, bullets, table cells, mono labels/tags/captions/source lines, chart axis text, timeline labels, page numbers, everything. Headings scale above it (34px+) so hierarchy survives. If content overflows at the floor, fix it by shortening copy, tightening padding/spacing, or splitting the slide — never step below 30px. Verify the floor with headless screenshots (e.g. `chrome.exe --headless --screenshot`) on the densest slides before delivering.

**Step 5 — Deliver.** Open the final deck in the browser (use `Start-Process` on Windows, never macOS `open`), send the absolute file path on its own line, plus one line on which template was picked and why, and any caveats (e.g. a template substitution or slides designed from scratch per §5).

## Content mapping

For lesson/document content, organize per-slide substance the same way a presenter needs it: one idea per slide, headlines presentation-ready, notes that don't belong on the slide stay out. If the user supplies a rich source and you need slide-by-slide derivation, the docx-to-ppt skill's Steps 1–3 describe content extraction; do NOT use its slidespec file.

## Common Mistakes

- Skipping Step 0 — silently producing a .pptx when the user wanted HTML (or vice versa)
- Asking any question the picker GUI already answered — `selection.json` is the source of truth
- Reading `selection.json` before the watcher exits 0 — a mid-write JSON is the classic failure mode
- Substituting fonts ("Inter is similar enough") — the typography IS the design system
- Recoloring or stripping decoration (grain, ribbons, stamps) to "simplify" — they are the identity
- Mixing components from two templates — each template is a closed visual system
- Letting content overflow the 1920×1080 stage instead of running Step 4 (the fit pass)
- Letting any text element drop below the user's 30px floor — trim copy or split the slide instead
- Using macOS `open` on Windows
- Mashing two templates' slides together instead of extending one
- Skipping the `picker\status.js` checkpoints — the user's loading screen stalls on the last known step; they may think the build hung

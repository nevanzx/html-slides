---
name: html-slides
description: Use for ANY request involving slides, a deck, a presentation, or slide content — "make slides", "build a deck", "presentation for class", "turn this lesson into slides", "HTML slides", or naming a template from beautiful-html-templates. This skill is the single destination for all slide work; it always produces browser HTML, never .pptx, unless the user explicitly asks for an editable PowerPoint file.
---

# HTML Slides

## Overview

Build presentation decks by **fully adapting the zarazhangrui/beautiful-html-templates library**: build the chosen template from the LOCAL clone at `picker\repo` (created/refreshed by `picker\install.ps1`) — never re-clone from GitHub while the local clone exists — replace placeholder content with real content, and deliver a standalone HTML file that looks exactly like the template — fonts, palette, every decorative element. The deliverable is HTML presented in a browser; never a .pptx.

There are **two separate routes** into a deck. Flow A is driven entirely by the agent inside a session: no picker window, no loading screen, no status file — the agent reads the content, builds, then audits and corrects its own output before delivering. Flow B is the picker GUI handing a `selection.json` to the watcher. Never mix the two.

## Step 0 — Routing (mandatory)

This skill is the funnel for **all** slide work. Any request for slides, a deck, or a presentation goes here and is delivered as browser HTML — do NOT ask "PowerPoint or HTML?" and do NOT hand off to pptx/docx-to-ppt. The only exception: when the user explicitly asks for an editable `.pptx` file, say the html-slides route builds HTML and offer to proceed with HTML unless they confirm PowerPoint. Do not infer from past projects.

## Step 0.5 — Choose the flow (mandatory)

| | **Flow A — in-session build** | **Flow B — picker build** |
|---|---|---|
| Trigger | The user asks you for slides in the conversation, names a template, or points at content | The prompt is `Build the html-slides deck described in …selection.json` (watcher-spawned), or the user says they came from the picker |
| Inputs | The conversation: named/attached files, pasted text, earlier context | `picker\selection.json` |
| UI | **None.** No picker window | Picker GUI owns the screen |
| `status.js` | **Never written** | Written at every checkpoint |
| Template | User-named, else chosen by you from `templates.json` | `template` field in the JSON |
| Correction | Mandatory self-check-and-fix loop (Step 4) | Same Step 4, reported through `status.js` |

Flow B applies **only** when the picker/watcher started the build. A leftover `selection.json` from an earlier picker run does NOT make the current request Flow B — if the user asked in chat, it is Flow A.

## Progress reporting — Flow B only

Flow A must never write `status.js`: there is no loading screen to feed, and writing it would overwrite the real picker state. Skip this whole section when running Flow A.

In Flow B, while building (a standalone `opencode run` spawned by `picker\watcher.ps1`), overwrite `D:\Python\html-slides\picker\status.js` (the file next to picker.html — NOT relative to your current working directory) at each checkpoint so the picker GUI's loading screen can show live progress. Overwrite the WHOLE file with the file-write tool (never a shell heredoc), as a single statement with exactly these fields:

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

**Step 1A — Flow A: intake from the session.**

No picker, no watcher, no status file. Gather the source material from the conversation, in this order:
1. Files the user named, attached, or linked.
2. Material pasted into the chat.
3. Relevant context from earlier in the same session.

- Never launch `picker.html`, never run `watcher.ps1`, never read `selection.json`, never write `status.js`, and never send the user to the GUI. Flow A is headless by design; those steps belong to Flow B only.
- If there is no usable source, ask **one** consolidated question (content/files, plus audience only if it changes the deck). Never a questionnaire, never "pick a template in the picker".
- **Template:** use the slug the user named. If they described a look ("clean", "bold", "dark", "academic"), map it onto `templates.json`. If they said nothing, choose the best match yourself from `templates.json` (subject, formality, density, colour mood) and move on — do not ask.
- **Slide count and density:** derive both from the content under the Density rule in Content mapping. Ask only when the user set a hard limit that fights the content.
- **Audience/occasion:** use what the user said. When unstated, default to classroom discussion for high school (the user's standing context).

**Step 1B — Flow B: launch the picker and read selection.json.**

If the user did not already come from the picker GUI:
```powershell
$browser = (Get-Content "D:\Python\html-slides\picker\web-browser.txt" -Raw).Trim()
Start-Process $browser -ArgumentList '--app=file:///D:/Python/html-slides/picker/picker.html?from=opencode'
```
Wait for the watcher to report the selection — bounded retry loop, NOT one blocking hour-long call:
```powershell
$watcher = "D:\Python\html-slides\picker\watcher.ps1"
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
Read every source: Flow B, each path in `content_files`; Flow A, each file or pasted block identified in Step 1A. Lines that start with `staged:` reference copies the picker GUI made via its native open-file dialog: resolve `staged:<name>` to `D:\Python\html-slides\picker\staged\<name>` and read that file. Read all other lines as absolute paths as-is. Organize slides from the source itself: one idea per slide; headlines presentation-ready and true to the source's titles; slide count and density from the JSON (`"auto"` → decide per slide from the content's weight under the Density rule in Content mapping — never shortcut content to keep the count down). If a path is missing, report which file was readable/missing and continue with what resolved. **Output location (mandatory):** Flow B saves to `output_dir` from selection.json when present, otherwise the folder of the first resolvable `content_files` path; Flow A saves to the folder of the first source file, or the working directory when the content was pasted. Name the file after the source's own title (e.g. `Week-1-Notebook-deck.html` in that folder).

**Step 3 — Build the deck in the chosen template.**
Import: `picker\repo` (refresh with `picker\install.ps1` ONLY if `templates.json` is older than the user wants or `repo` is missing). Locate the chosen slug in `picker\templates.json` (Flow B: the `template` field; Flow A: the slug you picked in Step 1A); if mapped to a missing slug, name the nearest equivalent based on scheme/density/formality and SAY you substituted. In the chosen template: follow the repo's own `AGENTS.md` §3–§5 — preserve fonts, palette, layout grid, slide-level CSS classes, decorative elements, and the navigation runtime; replace all placeholder content; duplicate the most appropriate layout for extra slides and update page-number labels (`NN / TT`); design missing layouts with the template's own design system — same fonts, colors, decor vocabulary, spacing rhythm, component grammar, chrome.

**Provenance block (REQUIRED):** the delivered HTML must begin its `<head>` with a provenance comment recording what produced it and from what source, so future debugging resolves provenance from the file itself:

```html
<head>
<!--
  deck-provenance
  generator: html-slides skill (opencode)
  template: <slug from templates.json>
  source_files:
    - <absolute path of each resolvable source, one per line (Flow B: `content_files` entries; Flow A: files read from the session; note `staged:` copies by their resolved staged path)>
  built_at: <ISO timestamp>
-->
```

If a content file could not be resolved (Step 2), list it under `unresolved:` with the reason. Never omit the block, even when the user doesn't ask for metadata.

**Step 4 — Self-check and correct (mandatory in both flows; the whole point of Flow A).** A deck is not done when it renders — it is done when audited. Run these checks on the built file, fix what fails, and run them again. Up to three passes; if a slide still fails, split it or cut copy — never shrink below the font floor.

1. **Source fidelity.** Re-open the source and walk it against the deck: every heading present with the source's own wording (Title fidelity), every definition attached to its term as a complete sentence (Definition preservation), every calculation present line by line with its actual numbers (Calculation preservation), nothing invented, nothing silently dropped.
2. **Arithmetic.** Recompute every number independently. A mismatch between deck and source is a defect — fix the deck; if the source itself is wrong, say so instead of propagating it.
3. **Render and look at every slide.** The template renders a fixed 1920×1080 stage that the browser scales uniformly (it may letterbox or pillarbox; content never reflows). Capture every slide with headless Chrome and read the PNGs: `chrome --headless --window-size=1920,1080 --screenshot=<png> "file:///.../deck.html#<n>"` for `deck-stage` decks (the `#N` hash is 1-indexed); for scroll decks, copy `install.ps1`'s technique (inject `scroll-snap-type:none` and set `.slides-container.scrollTop`). Inspect each capture for clipped text, text running past cards/columns, collisions with decor or the page-number chrome.
4. **Font floor (USER RULE, persistent).** Every text element stays at **30px or larger** at the 1920×1080 stage — body copy, bullets, table cells, mono labels/tags/captions/source lines, chart axis text, timeline labels, page numbers, everything. Headings stay above it (34px+) so hierarchy survives. Fix overflow by tightening line-height/padding, shortening copy, or splitting the slide — never step below 30px and never move the stage scale itself.
5. **Report what you caught.** Flow A's delivery message includes a short block listing the defects the audit found and what changed (e.g. "3 slides overflowed; 1 calculation mis-transcribed; 4 labels at 24px"). Never claim a clean build without having rendered and inspected the slides.

**Step 5 — Deliver.** The deck file must already sit in the source folder (Step 2's output location — verify before delivering). Open the final deck in the browser (use `Start-Process` on Windows, never macOS `open`), send the absolute file path on its own line, plus one line on which template was picked and why, and any caveats (e.g. a template substitution or slides designed from scratch per §5). Flow A: never mention the picker, the watcher, or a loading screen — there wasn't one.

## Content mapping

For lesson/document content, organize per-slide substance the same way a presenter needs it: one idea per slide, headlines presentation-ready, notes that don't belong on the slide stay out. If the user supplies a rich source and you need slide-by-slide derivation, the docx-to-ppt skill's Steps 1–3 describe content extraction; do NOT use its slidespec file.

**Title fidelity (REQUIRED):** slide titles use the source's own titles, in the source's own wording. Do not replace a source title with a figure of speech, idiom, pun, slogan, or invented hook, and never compress headings into ambiguous shorthand (e.g. "Two Payback, One PI" or "PI at 2 payback"). If a source heading is too long for the layout, shorten only by dropping words the sentence can live without — never by renaming the concept, and never by substituting metaphor for the source's terms. If the source has no title for a block, title it with the source's own first sentence or key term.

**Calculation preservation (REQUIRED):** every calculation, formula, or numeric computation that appears in the source content must appear on the slides too — never summarized away as "the formula applies here". Render it with the template's own component grammar (mono blocks, callout cards, or equation styling the template already provides) and respect the 30px font floor. Write it **line by line, one step per line, each line a complete labelled statement** — never a chained one-liner. For every step: label what it is, state the formula, substitute the actual numbers, then give the result with units. If a calculation drives a key takeaway, give it its own slide rather than a footnote.

Wrong — everything crammed on one line:

```text
PI = 15,193,298 ÷ 12,000,000 = 1.2661
```

Right — one step per line, each step labelled:

```text
Profitability Index (PI)
Step 1 — Present value of cash inflows: 15,193,298
Step 2 — Initial investment: 12,000,000
Step 3 — PI = PV of inflows ÷ Initial investment
Step 4 — PI = 15,193,298 ÷ 12,000,000
Step 5 — PI = 1.27
Decision: PI > 1, so the project is acceptable.
```

**Definition preservation (REQUIRED):** when a source introduces a new term, its definition must appear on the slide where the term first shows up — term + definition together, not the term alone or "see handout". Write each definition as a proper, complete sentence that can stand on its own (subject, verb, full thought), not a fragment: not "PI: ratio of inflows to investment" but "The profitability index is the ratio of the present value of cash inflows to the initial investment." Keep the source's meaning verbatim or near-verbatim; expanding in your own words risks drift. If the source defines many terms per slide, move definitions to follow-up slides rather than dropping them.

**Density (REQUIRED):** when density is `"auto"`, choose the density slide by slide from the content's own weight — do not default to sparse. Give each slide as much substance as it can hold cleanly at the template's type scale, and add a slide rather than compressing two ideas onto one or stripping detail to save slides. Shortcutting content to keep the slide count down is a failure, as is overflowing the stage; balance the two by letting the deck grow.

## Common Mistakes

- Skipping Step 0 — silently producing a .pptx when the user wanted HTML (or vice versa)
- Asking any question the picker GUI already answered — `selection.json` is the source of truth
- Running Flow A through the picker: launching the GUI, waiting on the watcher, reading a stale `selection.json`, or writing `status.js` when the user simply asked for slides in chat
- Asking a questionnaire in Flow A when the conversation already contains the content — one consolidated question at most, and template choice is yours
- Delivering a Flow A deck without rendering and inspecting every slide — the audit in Step 4 is the reason Flow A exists
- Reading `selection.json` before the watcher exits 0 — a mid-write JSON is the classic failure mode
- Substituting fonts ("Inter is similar enough") — the typography IS the design system
- Recoloring or stripping decoration (grain, ribbons, stamps) to "simplify" — they are the identity
- Mixing components from two templates — each template is a closed visual system
- Letting content overflow the 1920×1080 stage instead of running Step 4 (the fit pass)
- Letting any text element drop below the user's 30px floor — trim copy or split the slide instead
- Using macOS `open` on Windows
- Mashing two templates' slides together instead of extending one
- Skipping the `picker\status.js` checkpoints in Flow B — the user's loading screen stalls on the last known step; they may think the build hung
- Delivering an HTML deck without the `deck-provenance` comment block — debugging later can't tell what skill produced it or from which sources
- Dropping calculations from the source and just describing them in prose — the worked expression must be on the slide
- Chaining a calculation into one line ("PI = 15,193,298 ÷ 12,000,000 = 1.2661") — every step gets its own labelled line
- Showing a term without its definition when the source defines it — term and definition travel together
- Writing a definition as a fragment ("PI: inflows ÷ investment") instead of a complete sentence
- Renaming or "punching up" a source title with a figure of speech — titles keep the source's own wording
- Cramming or stripping content to hit a slide count — auto density grows the deck instead

# html-slides

An opencode skill that builds browser-based HTML slide decks (1920x1080 stage,
never .pptx) by adapting the
[zarazhangrui/beautiful-html-templates](https://github.com/zarazhangrui/beautiful-html-templates)
library — with a browser GUI ("picker") that decides everything *before* the AI
is asked anything.

## How it works

Two ways in, two different routes:

```
   Flow A (in session)                     Flow B (standalone)
   you ask opencode for slides            double-click the shortcut
            |                                       |
            |  agent reads the content              v
            |  picks the template          picker.html (GUI)
            |  builds the deck               - template grid x34
            |  audits every slide            - slide count / density
            |  fixes what it finds           - content file paths
            v                                       |
       deck.html                          writes selection.json
   (no GUI, no watcher, no status)                |
                                                  v
                                        watcher.ps1 -> opencode
                                          builds the deck + status
```

- **Flow A:** no picker, no watcher, no `status.js`. opencode reads the
  conversation, chooses the template itself, builds, then screenshots and
  audits every slide (content fidelity, arithmetic, overflow), keeping the
  30px font target — every deck embeds a mechanical autofit runtime that
  shrinks an overflowing slide's text to fit at any monitor size,
  corrects the defects, and delivers the file path.
- **Flow B:** the desktop shortcut opens the GUI + a background watcher; when
  you hit **BUILD DECK**, `opencode run` fires in a visible terminal, the deck
  builds automatically, and the loading screen shows live progress.
- Day-to-day context is fixed by the skill (classroom discussion decks) — the
  GUI only asks what actually varies: template, slide count, density, content
  files, notes.

## Install (after cloning)

Prereqs: Windows with **Chrome** installed, PowerShell 5.1 (built in), `git`,
and `opencode` on PATH for the build step.

```powershell
git clone https://github.com/nevanzx/html-slides
cd html-slides
powershell -NoProfile -ExecutionPolicy Bypass -File picker\install.ps1
```

`install.ps1` does everything, including the desktop part:

1. Clones the template library into `picker\repo` (depth 1).
2. Re-captures a title-slide screenshot for each template into
   `picker\screenshots\` with Chrome headless.
3. Generates `picker\templates.json` and `picker\library.json.js` (the GUI's
   data) and a BOM-less `picker\web-browser.txt` with your chrome.exe path.
4. **Creates the "HTML Slides Picker" shortcut on your Desktop and Start
   Menu.** Double-click it any time — no opencode needed for the picking part.
   The GUI opens in a borderless Chrome app window, so it behaves like an
   installed app rather than a browser tab.

Useful switches:

```powershell
# skip shortcut creation (dev machines, CI)
powershell -NoProfile -ExecutionPolicy Bypass -File picker\install.ps1 -SkipShortcuts

# force re-capture of every screenshot
powershell -NoProfile -ExecutionPolicy Bypass -File picker\install.ps1 -Force
```

If the shortcut doesn't show up, run `picker\picker.cmd` directly — same
behavior (opens the GUI app window + starts the watcher) — or re-run the
installer and read its error.

## Using it day to day

### From an opencode session (Flow A — no GUI)

Just ask: *"Make HTML slides from this lesson"* and point at the file. The skill
reads the content, picks the template itself, builds the deck, then screenshots
and audits every slide — content fidelity, arithmetic, overflow —
fixes what it finds (font fit is guaranteed by the autofit runtime every
deck embeds — no overflow at any resolution), and hands back the absolute
path plus a short list of what it corrected.

No picker window, no loading screen, no questions the chat already answers. Name
a template (*"use paper-tiger"*) to override the auto-pick; otherwise the skill
chooses one and tells you why in the delivery message.

### From the desktop (Flow B — picker + watcher)

1. Double-click **HTML Slides Picker**.

2. Filter or search the grid, click a template, fill slide count / density /
   lesson file path(s) / notes.

3. **BUILD DECK** (first run asks for the picker folder once, then writes
   silently forever after) → an opencode terminal opens and builds the deck.
   Rebuilding the same deck also works — each submission carries a timestamp so
   the watcher fires again.

## Tests

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-library.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-screenshots.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-watcher.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-picker-dom.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-shortcuts.ps1
```

41 checks, all expected to pass on commit. `test-picker-dom` and
`test-screenshots` need Chrome; `test-watcher` takes ~40s (real child
processes).

## Repo layout

```
SKILL.md                        the opencode skill (picker-first workflow)
picker/
  install.ps1                   clone -> copy -> screenshots -> shortcuts
  picker.html                   the GUI (single file, no network at runtime)
  picker.cmd                    shortcut target (GUI + watcher)
  watcher.ps1                   selection.json poller / opencode trigger
  templates.json, library.json.js    generated library data
  screenshots/<slug>-{1,2,3}.png  generated first-three-slide captures
  repo/                         cloned template library (gitignored)
  web-browser.txt               resolved chrome.exe path (gitignored)
  tests/                        5 validation scripts
docs/
  specs/                        design doc
  plans/                        implementation plan
```

## Design decisions

- No servers, no registry writes, no custom URL protocols — static file +
  PowerShell only.
- Chrome is required everywhere (capture, DOM test, GUI); Edge is deliberately
  not used.
- `selection.json` never gets deleted by automation, so a deck can always be
  rebuilt from it.
- The GUI validates path *format* only (file:// pages can't stat other files);
  genuinely missing files surface during deck extraction.

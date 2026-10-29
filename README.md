# html-slides

An opencode skill that builds browser-based HTML slide decks (1920x1080 stage,
never .pptx) by adapting the
[zarazhangrui/beautiful-html-templates](https://github.com/zarazhangrui/beautiful-html-templates)
library — with a browser GUI ("picker") that decides everything *before* the AI
is asked anything.

## How it works

Two ways in, one handoff artifact:

```
              +---------------------------+
   Flow A     |  you ask opencode        |  Flow B
   (in        |  for HTML slides         |  (standalone)
   session)   +------------+--------------+  double-click the shortcut
                           |                        |
                           v                        v
                 +---------------------------+
                 |  picker.html (GUI)        |
                 |  - template grid  x34     |
                 |  - slide count / density  |
                 |  - content file paths     |
                 +------------+--------------+
                              |
                    writes selection.json
                              |
                              v
                 +---------------------------+
                 |  watcher.ps1 -> opencode  |
                 |  builds the deck          |
                 +---------------------------+
```

- **Flow A:** opencode launches the GUI itself and waits for the watcher to
  report that `selection.json` appeared/changed.
- **Flow B:** the desktop shortcut opens the GUI + a background watcher; when
  you hit **BUILD DECK**, `opencode run` fires in a visible terminal and the
  deck builds automatically.
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

### From the desktop (no opencode open)

1. Double-click **HTML Slides Picker**.
2. Filter or search the grid, click a template, fill slide count / density /
   lesson file path(s) / notes.
3. **BUILD DECK** (first run asks for the picker folder once, then writes
   silently forever after) → an opencode terminal opens and builds the deck.

### From an opencode session

Just ask: *"Make HTML slides from the picker."* The skill launches the GUI,
waits for your submission, and builds with zero questions (the only fallback
ask happens when the watcher genuinely times out). Rebuilding the same deck
also works — each submission carries a timestamp so the watcher fires again.

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

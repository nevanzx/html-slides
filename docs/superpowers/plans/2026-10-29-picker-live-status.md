# Picker Live opencode Status — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** While opencode builds an html-slides deck, the picker browser page shows a live "Generating your deck" screen — step checklist, status log, Open-deck button, error card — driven by a status drop file opencode overwrites at each checkpoint.

**Architecture:** opencode (the skill) overwrites `picker\status.js` (a one-statement JS file assigning `window.__DECK_STATUS`) at every build checkpoint. `picker.html` re-injects `<script src="status.js?ts=…&n=…">` every 1.5 s — the same script-tag pattern its dialogs already use (`pollHelper`, picker.html:278) — and renders the status screen. No server, works over `file://`.

**Tech Stack:** Plain HTML/CSS/JS in `picker.html`; PowerShell 5.1 test scripts driving Chrome `--headless --dump-dom` (pattern of `picker\tests\test-picker-dom.ps1`).

**Spec:** `docs/superpowers/specs/2026-10-29-picker-live-status-design.md`

## Global Constraints

- No HTTP server, no fetch/XHR — status travels only via a script-tag-injected `status.js` (works from a `file://` page; per-poll cache-buster query).
- Poll interval: **1500 ms**. Submission timestamp (ms epoch) recorded at each BUILD; a status whose `updated_at` is older than `submitTs - 2000` is ignored in that session.
- Rejoin-on-load: show the status screen at page load only if a status exists with state `running`/`waiting`, or `done`/`error` with `updated_at` within the last **3600000 ms**.
- Stalled hint appears after **120000 ms** with no status at all following a submission.
- opencode must overwrite the **whole** `status.js` file with the agent file-write tool (never a shell heredoc) as a single statement: `window.__DECK_STATUS = { state, step, message, output, updated_at };`
- `state` ∈ `waiting|running|done|error`; `step` ∈ `read-selection|extract|build|fit|deliver`; `output` present only when `state:"done"`; `updated_at` is an ISO timestamp.
- Do **not** modify `watcher.ps1` detection logic; only `picker.html`, `SKILL.md`, new `picker\tests\test-status-screen.ps1`, and (transiently) `picker\status.js`.
- Keep picker's existing CSS variables and code style (IIFE, terse `$` helper, `Assert` test harness style).
- All test/diagnostic temp fixtures go under the system temp dir, never inside the repo.

---

### Task 1: SKILL.md — mandatory progress reporting section

**Files:**
- Modify: `SKILL.md` (insert after the Step 0 section, before `## Workflow`; also one line in `## Common Mistakes`)

**Interfaces:**
- Consumes: existing SKILL.md workflow step names (Steps 1–5).
- Produces: contract that `picker\status.js` is written at every build checkpoint with `state` ∈ `waiting|running|done|error`, `step` ∈ `read-selection|extract|build|fit|deliver`, `message`, `output` (done only), `updated_at` — Task 2's page code and Task 3's tests rely on exactly these field names/values.

- [ ] **Step 1: Edit SKILL.md**

Insert this section between the Step 0 section and `## Workflow`:

```markdown
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
```

In `## Common Mistakes`, add this bullet at the end of the list:

```markdown
- Skipping the `picker\status.js` checkpoints — the user's loading screen stalls on the last known step; they may think the build hung
```

- [ ] **Step 2: Commit**

```bash
git add SKILL.md
git commit -m "skill: mandate status.js checkpoints for picker live status"
```

---

### Task 2: Status screen — failing DOM tests

**Files:**
- Create: `picker\tests\test-status-screen.ps1`

**Interfaces:**
- Consumes: nothing yet (tests define the behavior contract).
- Produces: test script asserting picker.html behavior for `status.js` states via headless-Chrome dump-dom on temp fixtures. Assertions reference `data-status-state`, `statusOpenLink`, `.step done/active/failed` classes — Task 3 implements to these names.

- [ ] **Step 1: Write the test file**

```powershell
$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Assert($cond, $name) {
    if ($cond) { Write-Host "PASS: $name"; $script:pass++ }
    else       { Write-Host "FAIL: $name"; $script:fail++ }
}
$root = Split-Path (Split-Path $PSScriptRoot)
# Chrome resolve must probe HKCU before HKLM (per-user installs)
$chrome = $null
foreach ($hive in 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe') {
    $key = Get-ItemProperty $hive -ErrorAction SilentlyContinue
    $exe = $key.'(default)'
    if ($exe -and (Test-Path $exe)) { $chrome = $exe; break }
}
Assert ($chrome -and (Test-Path $chrome)) 'Chrome resolved (HKCU/HKLM)'
if ($fail -gt 0) { exit 1 }

function New-StatusFixture([string]$statusJs) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('picker-status-' + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Copy-Item (Join-Path $root 'picker\picker.html')       $tmp
    Copy-Item (Join-Path $root 'picker\library.json.js')   $tmp
    if ($statusJs) { Set-Content -Path (Join-Path $tmp 'status.js') -Value $statusJs -Encoding ASCII }
    return $tmp
}
function Get-StatusDom([string]$fixture) {
    $html = Join-Path $fixture 'picker.html'
    return (& $chrome --headless --disable-gpu --virtual-time-budget=5000 --dump-dom ('file:///' + ($html -replace '\\','/')) | Out-String)
}
function Remove-Fixture([string]$fixture) { Remove-Item -Recurse -Force $fixture }

$doneJs = @'
window.__DECK_STATUS = { state: "done", step: "deliver", message: "Deck built from status test", output: "C:\\Temp\\status-demo\\Week-1-deck.html", updated_at: new Date().toISOString() };
'@
$runningJs = @'
window.__DECK_STATUS = { state: "running", step: "build", message: "Building template demo", updated_at: new Date().toISOString() };
'@
$errorJs = @'
window.__DECK_STATUS = { state: "error", step: "build", message: "template repo missing", updated_at: new Date().toISOString() };
'@
$waitingJs = @'
window.__DECK_STATUS = { state: "waiting", step: "read-selection", message: "picked up selection.json", updated_at: new Date().toISOString() };
'@
$staleJs = @'
window.__DECK_STATUS = { state: "done", step: "deliver", message: "old run", output: "C:\\Temp\\old\\deck.html", updated_at: "2020-01-01T00:00:00.000Z" };
'@

# 1. done state: panel exists, state marked, Open deck link with slashed file URL
$fx = New-StatusFixture $doneJs; $dom = Get-StatusDom $fx
Assert ($dom -match 'id="statusScreen"')                          'status screen exists in markup'
Assert ($dom -match 'data-status-state="done"')                   'done state marked on panel'
Assert ($dom -match 'id="statusOpenLink"')                        'done renders Open deck link'
Assert ($dom -match 'href="file:///C:/Temp/status-demo/Week-1-deck\.html"') 'done link is a slashed file URL'
Assert (([regex]::Matches($dom, 'class="step done"')).Count -eq 5) 'done marks all five steps done'
Remove-Fixture $fx

# 2. running state: message rendered, build step active
$fx = New-StatusFixture $runningJs; $dom = Get-StatusDom $fx
Assert ($dom -match 'data-status-state="running"')                'running state marked on panel'
Assert ($dom -match 'Building template demo')                     'running message rendered'
Assert ($dom -match 'class="step active">Build template')         'running highlights the build step'
Remove-Fixture $fx

# 3. error state: failing step marked failed, message shown
$fx = New-StatusFixture $errorJs; $dom = Get-StatusDom $fx
Assert ($dom -match 'data-status-state="error"')                  'error state marked on panel'
Assert ($dom -match 'template repo missing')                      'error message rendered'
Assert ($dom -match 'class="step failed">Build template')         'error marks the failing step failed'
Assert ($dom -notmatch 'statusOpenLink')                          'error renders no open link'
Remove-Fixture $fx

# 4. waiting state: first step active, pickup message shown
$fx = New-StatusFixture $waitingJs; $dom = Get-StatusDom $fx
Assert ($dom -match 'picked up selection\.json')                  'waiting message rendered'
Assert ($dom -match 'class="step active">Read selection')         'waiting activates first step'
Remove-Fixture $fx

# 5. missing status.js: overlay stays hidden (idle)
$fx = New-StatusFixture $null; $dom = Get-StatusDom $fx
Assert ($dom -match 'data-status-state="idle"')                   'no status file leaves panel idle'
Assert ($dom -notmatch 'statusOpenLink')                          'no status file renders no open link'
Remove-Fixture $fx

# 6. stale status: older than the 1h rejoin window is ignored on load
$fx = New-StatusFixture $staleJs; $dom = Get-StatusDom $fx
Assert ($dom -notmatch 'statusOpenLink')                          'stale done status ignored on load'
Assert ($dom -match 'data-status-state="idle"')                   'stale status leaves panel idle'
Remove-Fixture $fx

if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0
```

- [ ] **Step 2: Run the test — expect FAILURES, not harness errors**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-status-screen.ps1` (from repo root `C:\Users\aclco\.claude\skills\html-slides`)
Expected: `Chrome resolved (HKCU/HKLM)` PASSES; state assertions FAIL (no `statusScreen` markup yet) → prints `N failed`, exit 1.

- [ ] **Step 3: Do NOT implement yet — commit the failing tests**

```bash
git add picker/tests/test-status-screen.ps1
git commit -m "test: status-screen DOM scenarios (red)"
```

---

### Task 3: Status screen — implement in picker.html

**Files:**
- Modify: `picker\picker.html` (CSS before `</style>`; markup before the `#toast` div; JS inside the main IIFE)

**Interfaces:**
- Consumes: `window.__DECK_STATUS` contract from Task 1 (fields `state`, `step`, `message`, `output`, `updated_at`); script-tag polling pattern from existing `pollHelper` (picker.html:278).
- Produces: status screen with `data-status-state` ∈ `idle|running|done|error` on `.status-panel`; `#statusOpenLink` anchor when done; step rows classed `step [done|active|failed]`.

- [ ] **Step 1: Add CSS (insert immediately before the closing `</style>`)**

```css
  #statusScreen { position:fixed; inset:0; background:var(--bg); display:none;
                  align-items:center; justify-content:center; z-index:900; }
  .status-panel { width:min(680px,90vw); background:var(--panel); border:1px solid var(--line);
                  border-radius:12px; padding:22px 26px; }
  .status-panel h2 { font-size:16px; margin-bottom:14px; }
  #statusScreen .step { font-size:13px; padding:4px 0; color:var(--dim); }
  #statusScreen .step::before { content:"○ "; }
  #statusScreen .step.done { color:var(--ok); }
  #statusScreen .step.done::before { content:"✓ "; }
  #statusScreen .step.active { color:var(--text); }
  #statusScreen .step.active::before { content:"◐ "; }
  #statusScreen .step.failed { color:var(--bad); }
  #statusScreen .step.failed::before { content:"✕ "; }
  #statusMsg { margin-top:12px; font-size:13px; }
  #statusScreen[data-status-state="error"] #statusMsg { color:var(--bad); }
  .status-log { margin-top:10px; max-height:180px; overflow-y:auto; font:11px monospace;
                color:var(--dim); border-top:1px solid var(--line); padding-top:8px; }
  .status-log div { padding:2px 0; overflow-wrap:anywhere; }
  #statusActions { margin-top:14px; }
  #statusActions .openLink { display:inline-block; background:var(--accent); color:#0a0e18;
                             padding:10px 18px; border-radius:8px; font-weight:600;
                             text-decoration:none; font-size:13px; }
  #statusActions .outHint { display:block; margin-top:8px; font-size:11px; color:var(--dim);
                            overflow-wrap:anywhere; }
  #statusHint { font-size:11px; color:var(--dim); margin-top:8px; }
  #statusBack { margin-top:14px; background:transparent; color:var(--dim); border:1px solid var(--line); }
```

- [ ] **Step 2: Add markup (insert immediately before `<div class="toast" id="toast"></div>`)**

```html
<section id="statusScreen">
  <div class="status-panel" id="statusPanel" data-status-state="idle">
    <h2>Generating your deck — live opencode status</h2>
    <div id="statusSteps"></div>
    <div id="statusMsg"></div>
    <div class="status-log" id="statusLog"></div>
    <div id="statusActions"></div>
    <div id="statusHint"></div>
    <button id="statusBack" class="mini">‹ back to picker</button>
  </div>
</section>
```

- [ ] **Step 3: Add status JS (insert inside the IIFE, right before `$('#buildBtn').onclick = writeJson;`)**

```js
    // ---- live build status (picker\status.js, written by opencode) ----
    const STEPS = [['read-selection','Read selection'], ['extract','Extract content'],
                   ['build','Build template'], ['fit','Font fit'], ['deliver','Deliver']];
    let subTs = null;          // Date.now() of the last BUILD submission this session
    let statusOpen = false;
    let pollTimer = null;
    let lastLogKey = '';

    function openStatus() {
        statusOpen = true;
        $('#statusScreen').style.display = 'flex';
    }
    function closeStatus() {
        statusOpen = false;
        $('#statusScreen').style.display = 'none';
    }
    function stopPolling() { if (pollTimer) { clearInterval(pollTimer); pollTimer = null; } }
    function startPolling() { stopPolling(); pollTimer = setInterval(tickStatus, 1500); }
    $('#statusBack').onclick = closeStatus;

    function renderChecklist(activeIdx, phase) {
        const box = $('#statusSteps');
        box.innerHTML = '';
        STEPS.forEach((s, i) => {
            const row = document.createElement('div');
            row.className = 'step';
            if (phase === 'done') row.classList.add('done');
            else if (i < activeIdx) row.classList.add('done');
            else if (phase === 'error' && i === activeIdx) row.classList.add('failed');
            else if (i === activeIdx) row.classList.add('active');
            row.textContent = s[1];
            box.appendChild(row);
        });
    }

    function pushLog(st) {
        const key = st.updated_at + '|' + st.step + '|' + st.message;
        if (key === lastLogKey) return;
        lastLogKey = key;
        const line = $('#statusLog');
        const div = document.createElement('div');
        div.textContent = new Date(st.updated_at).toLocaleTimeString() + '  ' +
            st.state.toUpperCase() + '  ' + st.message;
        line.appendChild(div);
        while (line.children.length > 60) line.firstChild.remove();
        line.scrollTop = line.scrollHeight;
    }

    function renderStatus(st) {
        if (!st) {
            if (!statusOpen) return;
            $('#statusPanel').dataset.statusState = 'running';
            renderChecklist(0, 'pending');
            $('#statusMsg').textContent = 'waiting for opencode to pick up…';
            $('#statusHint').textContent = (subTs && Date.now() - subTs > 120000)
                ? 'opencode hasn\'t picked up yet — run picker\\watcher.ps1 or ask opencode to build picker\\selection.json'
                : '';
            return;
        }
        if (subTs && new Date(st.updated_at).getTime() < subTs - 2000) return renderStatus(null);
        if (!statusOpen) openStatus();
        $('#statusHint').textContent = '';
        pushLog(st);
        const idx = Math.max(0, STEPS.findIndex(x => x[0] === st.step));
        const actions = $('#statusActions');
        actions.innerHTML = '';
        if (st.state === 'done') {
            $('#statusPanel').dataset.statusState = 'done';
            renderChecklist(STEPS.length - 1, 'done');
            $('#statusMsg').textContent = st.message || 'Deck ready';
            if (st.output) {
                const a = document.createElement('a');
                a.id = 'statusOpenLink';
                a.href = 'file://' + encodeURI(st.output.replace(/\\/g, '/'));
                a.target = '_blank'; a.rel = 'noopener';
                a.className = 'openLink';
                a.textContent = 'Open deck';
                a.onclick = stopPolling;
                actions.appendChild(a);
                const hint = document.createElement('span');
                hint.className = 'outHint';
                hint.textContent = st.output;
                actions.appendChild(hint);
            } else {
                const hint = document.createElement('span');
                hint.className = 'outHint';
                hint.textContent = 'deck path not reported — check the opencode output';
                actions.appendChild(hint);
            }
            stopPolling();
            return;
        }
        if (st.state === 'error') {
            $('#statusPanel').dataset.statusState = 'error';
            renderChecklist(idx, 'error');
            $('#statusMsg').textContent = st.message || 'Build failed';
            stopPolling();
            return;
        }
        $('#statusPanel').dataset.statusState = 'running';
        renderChecklist(st.state === 'waiting' ? 0 : idx, 'running');
        $('#statusMsg').textContent = st.message ||
            (st.state === 'waiting' ? 'opencode picked up selection.json' : 'working…');
    }

    function tickStatus() {
        const s = document.createElement('script');
        s.src = 'status.js?ts=' + (subTs || 0) + '&n=' + Date.now();   // unique URL: fresh read every tick
        window.__DECK_STATUS = null;
        s.onerror = () => { s.remove(); if (statusOpen) renderStatus(null); };
        s.onload = () => {
            s.remove();
            const st = window.__DECK_STATUS;
            window.__DECK_STATUS = null;
            renderStatus(st || null);
            if (!st && !statusOpen) stopPolling();
        };
        document.head.appendChild(s);
    }

    // rejoin: on load, show the screen if a build is live or resolved recently (< 1h)
    (function joinStatus() {
        const s = document.createElement('script');
        s.src = 'status.js?ts=0&n=' + Date.now();
        window.__DECK_STATUS = null;
        s.onerror = () => s.remove();
        s.onload = () => {
            s.remove();
            const st = window.__DECK_STATUS;
            window.__DECK_STATUS = null;
            if (!st) return;
            const age = Date.now() - new Date(st.updated_at).getTime();
            if (st.state === 'running' || st.state === 'waiting' || age < 3600000) {
                openStatus();
                renderStatus(st);
                if (st.state === 'running' || st.state === 'waiting') startPolling();
            }
        };
        document.head.appendChild(s);
    })();
```

- [ ] **Step 4: Replace `finish()` body (submission now opens the status screen instead of toasting)**

Replace the existing `finish()` (picker.html:341-344):

```js
    function finish() {
        subTs = Date.now();
        lastLogKey = '';
        openStatus();
        renderStatus(null);      // waiting UI until opencode's first checkpoint lands
        startPolling();
    }
```

- [ ] **Step 5: Run the status tests — expect PASS**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-status-screen.ps1`
Expected: `all N checks passed`, exit 0. If `done marks all five steps done` fails, check that `renderChecklist(STEPS.length - 1, 'done')` classes all five rows.

- [ ] **Step 6: Run the existing DOM regression test**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-picker-dom.ps1`
Expected: all previous checks still pass (grid renders, modal shell, etc.) — the status screen must not affect the picker view.

- [ ] **Step 7: Commit**

```bash
git add picker/picker.html
git commit -m "feat(picker): live opencode status screen with polling"
```

---

### Task 4: Sanity — watcher regression + end-to-end manual check

**Files:**
- Test: `picker\tests\test-watcher.ps1` (run only — no edits)

**Interfaces:**
- Consumes: Tasks 1–3 complete.

- [ ] **Step 1: Run watcher regression**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-watcher.ps1`
Expected: passes unchanged (watcher detection untouched by this feature).

- [ ] **Step 2: Run full status + DOM suite**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-status-screen.ps1; powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-picker-dom.ps1`
Expected: both exit 0.

- [ ] **Step 3: Manual end-to-end (requires a normal browser, no skill run needed)**

1. Simulate opencode's side by hand:
   ```powershell
   Set-Content picker\status.js -Value ('window.__DECK_STATUS = { state: "running", step: "extract", message: "test checkpoint", updated_at: "' + (Get-Date).ToUniversalTime().ToString('o') + '" };')
   ```
2. Open `picker.html` in a normal (non-headless) browser → the "Generating your deck" screen should appear showing the test checkpoint in running state (no Open deck button).
3. Delete `picker\status.js` → the screen falls back to "waiting for opencode to pick up…", and the stalled hint appears after 2 minutes.
4. Clean up: delete `picker\status.js`. It is a runtime artifact owned by opencode — it must NOT be committed to the repo.

- [ ] **Step 4: Verify repo state**

Run: `git status --short picker/status.js`
Expected: no output (file never tracked; if it shows as untracked, delete it — `Remove-Item picker\status.js`).

---

## Self-Review

- **Spec coverage:** status.js format + mandatory checkpoints (Task 1); overlay with checklist/log/states/Open-deck/error/stalled-hint (Task 3); script-tag polling + cache-buster (Task 3); staleness flush + 2s tolerance (Task 3 `renderStatus` guard); rejoin-on-load ≤1h (Task 3 `joinStatus`); tests (Tasks 2, 4); both flows covered via Task 1 wording; safe-to-close untouched behavior (no code change needed). All spec sections map to tasks.
- **Placeholder scan:** no TBDs; every code step shows full code; test file given verbatim.
- **Type consistency:** `window.__DECK_STATUS`, `state/step/message/output/updated_at`, `data-status-state`, `#statusOpenLink`, `.step done/active/failed` used identically across Tasks 1–3 and asserted in Task 2's test.

# HTML Slides Picker GUI — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a browser GUI ("picker") to the `html-slides` skill that collects every deck question up front and hands opencode a `selection.json`, usable either from a live opencode session or standalone via an app-mode browser shortcut.

**Architecture:** Single-file `picker.html` (inline CSS/JS) renders the 34-template library from a generated `library.json.js` with screenshots; submission writes `selection.json` via the File System Access API. A PowerShell watcher polls the file (content-hash compare) and, in standalone mode, fires `opencode run` in a visible terminal. `install.ps1` clones the template repo, captures title-slide screenshots with Edge headless, generates `templates.json`/`library.json.js`, and installs Desktop + Start Menu shortcuts.

**Tech Stack:** Vanilla HTML/CSS/JS, Windows PowerShell 5.1, Edge headless screenshots, git, Windows Terminal.

**Spec:** `docs/specs/2026-10-29-picker-gui-design.md` (sibling of this file)

## Global Constraints

- All scripts target Windows PowerShell 5.1 (`powershell.exe`) unless stated otherwise.
- All file I/O UTF-8; Windows backslash paths preserved verbatim inside `selection.json`.
- Fixed context baked into artifacts: occasion = classroom discussion; audience = high school (never surfaced); no mood field; title text from source; special slides = AI discretion.
- Selection JSON schema (exact): `{"template": "<slug>", "slide_count": <number> | "auto", "density": "auto"|"sparse"|"balanced"|"dense", "content_files": [<absolute paths>], "notes": "<string>"}`.
- `selection.json` is never deleted or consumed by automation.
- Working directory: `C:\Users\aclco\.claude\skills\html-slides\` (*skill root*); all picker artifacts under `picker\`.
- No servers, no registry writes, no custom URL protocols anywhere.
- Deviation from spec (deliberate, record only): a file:// page cannot stat other files, so the GUI validates path *format* (drive-letter / UNC pattern) inline instead of existence; opencode reports genuinely missing files during Step-2 extraction.
- Every PowerShell invocation in tests/scripts: `-NoProfile -ExecutionPolicy Bypass`.
- App window opened with `--app="file:///.../picker.html"` (Edge first, Chrome fallback).

---

## File Structure

```
picker/
  install.ps1        sections built up across Tasks 1/2/5: clone -> templates.json +
                     library.json.js -> screenshots -> browser.txt -> shortcuts
  templates.json     generated: {"updated_at", "templates":[...]} (adults + opencode read this)
  library.json.js    generated: window.LIBRARY = <same payload>; (file:// page consumes this)
  screenshots/*.png  generated: 34 title-slide captures (1920x1080)
  repo/              git clone of beautiful-html-templates (gitignored)
  web-browser.txt    generated: one line, absolute browser exe path (gitignored)
  picker.html        the GUI (single file, inline CSS/JS, <script src="library.json.js">)
  picker.cmd         shortcut target: opens GUI app window + starts hidden watcher
  watcher.ps1        content-hash poll of selection.json; fires `opencode run` visibly
  tests/
    test-library.ps1
    test-screenshots.ps1
    test-watcher.ps1
    test-picker-dom.ps1
    test-shortcuts.ps1
selection.json       canonical handoff artifact (gitignored)
.gitignore
```

Tracking: git initialized in skill root (Task 1 Step 1; skip when `.git` already exists). Generated files `templates.json` and `library.json.js` ARE tracked (a bare machine needs them); `repo/`, `screenshots/`, `web-browser.txt`, `selection.json` are NOT.

---

### Task 1: Git tracking + repo clone + templates.json / library.json.js

**Files:**
- Create: `picker\install.ps1` (sections 1–2)
- Create: `picker\tests\test-library.ps1`
- Create: `.gitignore`

**Interfaces:**
- Consumes: `repo/index.json` (repo main-branch commit; fields used: `templates[].slug,name,tagline,scheme,formality,density,slide_count,occasion[]`).
- Produces: `picker\templates.json` = `{"updated_at":"<ISO8601 UTC>","templates":[{slug:string, name:string, tagline:string, scheme:string|null, formality:string|null, density:string|null, slide_count:number|null, occasion:[string]}]}`. `picker\library.json.js` = `window.LIBRARY = <that same payload>;`. All later tasks read ONLY these two, never the repo.

- [ ] **Step 1: git init + baseline (skip when .git exists)**

From skill root:

```powershell
if (-not (Test-Path .git)) { git init }
```

Create `.gitignore` at skill root:

```
picker/repo/
picker/screenshots/
picker/web-browser.txt
selection.json
```

Commit:

```bash
git add .gitignore docs/specs/2026-10-29-picker-gui-design.md docs/plans/2026-10-29-picker-gui.md SKILL.md
git commit -m "docs: picker GUI spec, plan, gitignore"
```

- [ ] **Step 2: Write failing test (picker/tests/test-library.ps1)**

```powershell
$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Assert($cond, $name) {
    if ($cond) { Write-Host "PASS: $name"; $script:pass++ }
    else       { Write-Host "FAIL: $name"; $script:fail++ }
}
$root      = Split-Path (Split-Path $PSScriptRoot)   # picker\tests -> picker -> skill root
$templates = Join-Path $root 'picker\templates.json'
$library   = Join-Path $root 'picker\library.json.js'

Assert (Test-Path $templates) 'templates.json exists'
Assert (Test-Path $library)   'library.json.js exists'
if ($fail -gt 0) { exit 1 }

$data = Get-Content $templates -Raw -Encoding UTF8 | ConvertFrom-Json
Assert ($data.updated_at -as [datetime]) 'updated_at parses as datetime'
Assert ($data.templates.Count -ge 30) "template count >= 30 (got $($data.templates.Count))"
Assert ($data.templates.Count -eq ($data.templates | ForEach-Object slug | Sort-Object -Unique).Count) 'slugs unique'
$t0 = $data.templates[0]
foreach ($k in @('slug','name','tagline','scheme','formality','density','slide_count','occasion')) {
    Assert ($t0.PSObject.Properties.Name -contains $k) "key '$k' present"
}

$lib  = Get-Content $library -Raw -Encoding UTF8
Assert ($lib.StartsWith('window.LIBRARY = ')) 'library.json.js exposes window.LIBRARY'
$payload = ($lib -replace '^window\.LIBRARY = ', '' -replace ';\s*\r?\n?\s*$', '') | ConvertFrom-Json
Assert ($payload.templates.Count -eq $data.templates.Count) 'library payload matches templates.json'
Assert ($payload.updated_at -eq $data.updated_at) 'updated_at matches'

Write-Host '----'
if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0
```

- [ ] **Step 3: Run test, verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-library.ps1`
Expected: `FAIL: templates.json exists`, `FAIL: library.json.js exists`, exit 1.

- [ ] **Step 4: Implement install.ps1 (sections 1–2)**

Create `picker\install.ps1`:

```powershell
param([switch]$Force, [switch]$SkipShortcuts)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ---------- section 1: clone / refresh the template repo ----------
$repo = Join-Path $PSScriptRoot 'repo'
if (-not (Test-Path (Join-Path $repo '.git'))) {
    git clone --depth 1 https://github.com/zarazhangrui/beautiful-html-templates $repo
} else {
    git -C $repo fetch --depth 1 origin main
    git -C $repo reset --hard origin/main
}

# ---------- section 2: templates.json + library.json.js ----------
$index = Get-Content (Join-Path $repo 'index.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$templates = @(
    $index.templates | ForEach-Object {
        [ordered]@{
            slug        = $_.slug
            name        = $_.name
            tagline     = $_.tagline
            scheme      = $_.scheme
            formality   = $_.formality
            density     = $_.density
            slide_count = $_.slide_count
            occasion    = @($_.occasion)
        }
    }
)
$payload = [ordered]@{
    updated_at = (Get-Date).ToUniversalTime().ToString('o')
    templates  = $templates
}
$json = ConvertTo-Json $payload -Depth 5
Set-Content (Join-Path $PSScriptRoot 'templates.json')   -Value $json -Encoding UTF8
Set-Content (Join-Path $PSScriptRoot 'library.json.js')  -Value ('window.LIBRARY = ' + $json + ';' + [Environment]::NewLine) -Encoding UTF8

# ---------- sections 3+ are appended in later tasks ----------
Write-Host 'install: sections 1-2 done (templates.json + library.json.js)'
```

- [ ] **Step 5: Run installer and test**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File picker\install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-library.ps1
```

Expected: clone completes; test prints `all N checks passed` (N = 16), exit 0.

- [ ] **Step 6: Commit**

```bash
git add picker/install.ps1 picker/templates.json picker/library.json.js picker/tests/test-library.ps1
git commit -m "feat(picker): repo clone + templates.json/library.json.js generation"
```

---

### Task 2: Screenshot capture with Edge headless

**Files:**
- Modify: `picker\install.ps1` (append section 3)
- Create: `picker\tests\test-screenshots.ps1`

**Interfaces:**
- Consumes: slugs from `templates.json` (Task 1); per-slug title-slide HTML at `picker\repo\<slug>\template.html`.
- Produces: `picker\screenshots\<slug>.png` for every template slug, each > 20 KB.

- [ ] **Step 1: Write failing test (picker/tests/test-screenshots.ps1)**

```powershell
$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Assert($cond, $name) {
    if ($cond) { Write-Host "PASS: $name"; $script:pass++ }
    else       { Write-Host "FAIL: $name"; $script:fail++ }
}
$root  = Split-Path (Split-Path $PSScriptRoot)
$json  = Get-Content (Join-Path $root 'picker\templates.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$ssDir = Join-Path $root 'picker\screenshots'
Assert (Test-Path $ssDir) 'screenshots dir exists'
if ($fail -gt 0) { exit 1 }

$missing = @(); $tiny = @()
foreach ($t in $json.templates) {
    $png = Join-Path $ssDir ($t.slug + '.png')
    if (-not (Test-Path $png)) { $missing += $t.slug; continue }
    if ((Get-Item $png).Length -lt 20KB) { $tiny += $t.slug }
}
Assert ($missing.Count -eq 0) ("no missing screenshots" + $(if ($missing.Count) { ': ' + ($missing -join ',') }))
Assert ($tiny.Count   -eq 0) ("no blank/too-small captures" + $(if ($tiny.Count)   { ': ' + ($tiny -join ',') }))
if ($fail -gt 0) { exit 1 }
Write-Host "all $pass checks passed"
```

- [ ] **Step 2: Run test, verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-screenshots.ps1`
Expected: `FAIL: screenshots dir exists`, exit 1.

- [ ] **Step 3: Implement capture (append section 3 to install.ps1)**

```powershell
# ---------- section 3: title-slide screenshots via Edge headless ----------
$ssDir = Join-Path $PSScriptRoot 'screenshots'
New-Item -ItemType Directory -Force -Path $ssDir | Out-Null
$edgeKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue
$edge = $edgeKey.'(default)'
if (-not $edge -or -not (Test-Path $edge)) { throw 'Edge (msedge.exe) not found via App Paths key' }

$bad = @()
foreach ($t in $templates) {
    $png  = Join-Path $ssDir ($t.slug + '.png')
    $html = Join-Path $repo ($t.slug + '\template.html')
    $upToDate = (Test-Path $png) -and (Get-Item $png).Length -gt 20KB
    if ($upToDate -and -not $Force) { continue }
    if (-not (Test-Path $html)) { $bad += ('no template.html: ' + $t.slug); continue }
    $url = 'file:///' + ($html -replace '\\', '/')
    & $edge --headless --disable-gpu --hide-scrollbars --default-background-color=FFFFFFFF `
        '--window-size=1920,1080' "--screenshot=$png" $url 2>$null | Out-Null
    for ($i = 0; $i -lt 20; $i++) {
        if ((Test-Path $png) -and (Get-Item $png).Length -gt 20KB) { break }
        Start-Sleep -Milliseconds 500
    }
    if (-not $upToDate) {
        if ((-not (Test-Path $png)) -or (Get-Item $png).Length -le 20KB) { $bad += ('capture failed: ' + $t.slug) }
    }
}
if ($bad.Count -gt 0) { throw ($bad -join '; ') }
Write-Host "screenshots: ready for $($templates.Count) templates"
```

(Locate check during execution: if `repo\<slug>\template.html` is not the real layout, run `Get-ChildItem $repo -Recurse -Filter template.html` once, derive the actual per-slug mapping, and adjust ONLY the `$html = ...` line.)

- [ ] **Step 4: Run installer + tests**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File picker\install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-screenshots.ps1
```

Expected: ~34 PNGs; `all N checks passed`; exit 0. Rerun installer once more — everything skips (up-to-date path).

- [ ] **Step 5: Commit**

```bash
git add picker/install.ps1 picker/tests/test-screenshots.ps1
git commit -m "feat(picker): Edge headless title-slide screenshot capture"
```

---

### Task 3: watcher.ps1 (content-hash poll)

**Files:**
- Create: `picker\watcher.ps1`
- Create: `picker\tests\test-watcher.ps1`

**Interfaces:**
- Consumes: `picker\selection.json` (any writer: GUI or tests).
- Produces (contract): `powershell -NoProfile -ExecutionPolicy Bypass [-File] picker\watcher.ps1 [-NotifyOnly] [-TimeoutSec <int>=3600] [-IntervalSec <int>=1]` — exits **0** the moment content changes (fires `opencode run` in a visible terminal unless `-NotifyOnly`), exits **3** on idle timeout with a soft message; never modifies/deletes `selection.json`; only one watcher per machine (global mutex).

- [ ] **Step 1: Write failing test (picker/tests/test-watcher.ps1)**

```powershell
$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Assert($cond, $name) {
    if ($cond) { Write-Host "PASS: $name"; $script:pass++ }
    else       { Write-Host "FAIL: $name"; $script:fail++ }
}
$picker  = Split-Path $PSScriptRoot          # picker\tests -> picker
$sel     = Join-Path $picker 'selection.json'
$watcher = Join-Path $picker 'watcher.ps1'
Assert (Test-Path $watcher) 'watcher.ps1 exists'

function Start-Watcher([string[]]$extra) {
    $all = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $watcher) + $extra
    Start-Process powershell -ArgumentList $all -PassThru -WindowStyle Hidden
}

# --- test 1: fresh trigger fires fast + file preserved
if (Test-Path $sel) { Remove-Item $sel -Force }
$p = Start-Watcher @('-NotifyOnly','-TimeoutSec','20')
Start-Sleep -Seconds 2
Set-Content -Path $sel -Value '{"template":"daisy-days"}' -Encoding UTF8
$sw = [Diagnostics.Stopwatch]::StartNew()
$p.WaitForExit(8000) | Out-Null
$sw.Stop()
Assert ($p.HasExited -and $p.ExitCode -eq 0 -and $sw.Elapsed.TotalSeconds -lt 8) "fresh trigger exits 0 within 8s (took $([math]::Round($sw.Elapsed.TotalSeconds,1))s)"
Assert (Test-Path $sel) 'selection.json preserved'

# --- test 2: same-mtime overwrite still triggers (hash-based)
Set-Content -Path $sel -Value '{"template":"monochrome"}' -Encoding UTF8
$origTime = (Get-Item $sel).LastWriteTimeUtc
$p = Start-Watcher @('-NotifyOnly','-TimeoutSec','20')
Start-Sleep -Seconds 2
Set-Content -Path $sel -Value '{"template":"broadside"}' -Encoding UTF8
(Get-Item $sel).LastWriteTimeUtc = $origTime      # force SHA-based detection
$sw = [Diagnostics.Stopwatch]::StartNew()
$p.WaitForExit(8000) | Out-Null
$sw.Stop()
Assert ($p.HasExited -and $p.ExitCode -eq 0 -and $sw.Elapsed.TotalSeconds -lt 8) 'same-mtime overwrite triggers'

# --- test 3: timeout -> exit 3, soft, sane duration
if (Test-Path $sel) { Remove-Item $sel -Force }
$p = Start-Watcher @('-NotifyOnly','-TimeoutSec','3')
$sw = [Diagnostics.Stopwatch]::StartNew()
$p.WaitForExit(10000) | Out-Null
$sw.Stop()
Assert ($p.ExitCode -eq 3) 'timeout exit code 3'
Assert ($sw.Elapsed.TotalSeconds -ge 2.5 -and $sw.Elapsed.TotalSeconds -lt 9) "timeout duration sane ($([math]::Round($sw.Elapsed.TotalSeconds,1))s)"

# --- cleanup
if (Test-Path $sel) { Remove-Item $sel -Force }
if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0
```

- [ ] **Step 2: Run test, verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-watcher.ps1`
Expected: `FAIL: watcher.ps1 exists`, exit 1.

- [ ] **Step 3: Implement watcher.ps1**

```powershell
param(
    [int]$TimeoutSec  = 3600,
    [int]$IntervalSec = 1,
    [switch]$NotifyOnly
)
$ErrorActionPreference = 'Stop'

$created = $false
$mtx = $null
try {
    $mtx = New-Object System.Threading.Mutex($true, 'Global\html-slides-picker-watcher', [ref]$created)
    if (-not $created) { exit 0 }   # a watcher is already on duty
} catch { }

function Get-State {
    if (-not (Test-Path $selectionPath)) { return '<none>' }
    $bytes = [IO.File]::ReadAllBytes($selectionPath)
    return 'len=' + $bytes.Length +
        ';sha=' + ([BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData($bytes)) -replace '-','')
}
$selectionPath = Join-Path $PSScriptRoot 'selection.json'
$baseline = Get-State
$started = Get-Date
Write-Host "watcher: waiting for selection.json change (cap ${TimeoutSec}s)..."

try {
    while ($true) {
        Start-Sleep -Seconds $IntervalSec
        if ((Get-State) -ne $baseline) {
            Write-Host 'watcher: selection.json changed.'
            if ($NotifyOnly) { exit 0 }
            $prompt  = "Build the html-slides deck described in $selectionPath. Never re-ask any question the JSON already answers."
            $inner   = 'opencode run "' + ($prompt -replace '"', '\"') + '"'
            if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
                Start-Process wt.exe -ArgumentList @('powershell.exe','-NoProfile','-NoExit','-Command', $inner)
            } else {
                Start-Process powershell.exe -ArgumentList @('-NoProfile','-NoExit','-Command', $inner)
            }
            exit 0
        }
        if (((Get-Date) - $started).TotalSeconds -gt $TimeoutSec) {
            Write-Host 'watcher: no change after cap; giving up softly.'
            exit 3
        }
    }
} finally {
    if ($created -and $mtx) { $mtx.ReleaseMutex(); $mtx.Dispose() }
}
```

NOTE on `$selectionPath`: it must be defined BEFORE `Get-State` is *called*, not before it's defined — the snippet above sets `$selectionPath` after the function declaration, which is correct because PowerShell resolves at call time. Do not reorder; do not move `$baseline = Get-State` above the assignment.

- [ ] **Step 4: Run test, verify it passes**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-watcher.ps1`
Expected: `all 4 checks passed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add picker/watcher.ps1 picker/tests/test-watcher.ps1
git commit -m "feat(picker): selection.json content-hash watcher"
```

---

### Task 4: picker.html — the GUI

**Files:**
- Create: `picker\picker.html`
- Create: `picker\tests\test-picker-dom.ps1`

**Interfaces:**
- Consumes: `library.json.js` (`window.LIBRARY.templates[].slug,name,tagline,scheme,formality,density,slide_count,occasion`), screenshots at `screenshots/<slug>.png`.
- Produces: valid `selection.json` (Global Constraints schema); accepts `?from=opencode` (informational banner); remembers last template in `localStorage.picker.lastTemplate`; remembers output folder in IndexedDB `picker/kv['dir']` (a FileSystemDirectoryHandle).

- [ ] **Step 1: Write failing test (picker/tests/test-picker-dom.ps1)**

```powershell
$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Assert($cond, $name) {
    if ($cond) { Write-Host "PASS: $name"; $script:pass++ }
    else       { Write-Host "FAIL: $name"; $script:fail++ }
}
$root = Split-Path (Split-Path $PSScriptRoot)
$edgeKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue
$edge = $edgeKey.'(default)'
Assert ($edge -and (Test-Path $edge)) 'Edge resolved'
$html = Join-Path $root 'picker\picker.html'
Assert (Test-Path $html) 'picker.html exists'
if ($fail -gt 0) { exit 1 }

$dom = & $edge --headless --disable-gpu --virtual-time-budget=4000 --dump-dom ('file:///' + ($html -replace '\\','/')) | Out-String
Assert ($dom -match 'data-template-card=') 'grid renders template cards'
$cardCount = ([regex]::Matches($dom, 'data-template-card=')).Count
Assert ($cardCount -ge 30) "cards rendered >= 30 (got $cardCount)"
Assert ($dom -match 'BUILD DECK') 'build-deck button rendered'
Assert ($dom -match 'json-library-badge') 'library badge rendered'
Assert ($dom -match 'content_files') 'content files textarea rendered'
if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0
```

- [ ] **Step 2: Run test, verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-picker-dom.ps1`
Expected: `FAIL: picker.html exists`, exit 1.

- [ ] **Step 3: Implement picker.html**

Single file. Structure exactly this; polish is welcome as long as IDs/data-attributes/behavior stay the contract. Full content follows.

*Head + styles + markup:*

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>HTML Slides Picker</title>
<style>
  :root { --bg:#10131a; --panel:#171b25; --line:#2a3140; --text:#e8ebf2; --dim:#96a0b5;
          --accent:#6ea8ff; --ok:#4fd6a2; --bad:#ff7a7a; }
  * { box-sizing: border-box; margin: 0; }
  body { background:var(--bg); color:var(--text); font:14px/1.45 "Segoe UI", system-ui, sans-serif;
         height:100vh; display:flex; flex-direction:column; }
  header { display:flex; align-items:center; gap:10px; padding:12px 18px;
           background:var(--panel); border-bottom:1px solid var(--line); }
  header h1 { font-size:15px; font-weight:600; letter-spacing:.4px; }
  header .badge { margin-left:auto; font-size:11px; color:var(--dim); }
  header .from-opencode { font-size:11px; color:var(--ok); display:none;
                          border:1px solid var(--ok); border-radius:20px; padding:2px 10px; }
  main { display:flex; flex:1; min-height:0; }
  #rail { width:230px; border-right:1px solid var(--line); background:var(--panel);
          padding:12px; overflow-y:auto; flex-shrink:0; }
  #rail h2 { font-size:11px; text-transform:uppercase; letter-spacing:1px; color:var(--dim); margin:10px 0 6px; }
  #rail input[type=search] { width:100%; background:var(--bg); color:var(--text);
                             border:1px solid var(--line); border-radius:6px; padding:6px 8px; font-size:13px; }
  #rail label.chip { display:block; font-size:12px; padding:3px 0; cursor:pointer; }
  .count { font-size:11px; color:var(--dim); margin-top:8px; }
  #grid { flex:1; overflow-y:auto; padding:16px;
          display:grid; grid-template-columns:repeat(auto-fill,minmax(220px,1fr));
          gap:14px; align-content:start; }
  .card { background:var(--panel); border:2px solid transparent; border-radius:10px;
          overflow:hidden; cursor:pointer; }
  .card img { width:100%; aspect-ratio:16/9; object-fit:cover; display:block; background:#000; }
  .card .meta { padding:8px 10px; }
  .card .name { font-weight:600; font-size:13px; }
  .card .tag { font-size:11px; color:var(--dim); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .card.sel { border-color:var(--accent); }
  .card.sel .name::after { content:"  ✓"; color:var(--ok); }
  footer { border-top:1px solid var(--line); background:var(--panel); padding:14px 18px; }
  #ribbon { font-size:12px; margin-bottom:10px; }
  #ribbon b { color:var(--accent); }
  .row { display:flex; gap:18px; align-items:center; flex-wrap:wrap; }
  .field { display:flex; flex-direction:column; gap:4px; }
  .field span { font-size:11px; text-transform:uppercase; letter-spacing:1px; color:var(--dim); }
  .field input[type=number], .field select { background:var(--bg); color:var(--text);
      border:1px solid var(--line); border-radius:6px; padding:6px 10px; width:120px; }
  #content_files { width:100%; height:64px; background:var(--bg); color:var(--text);
      border:1px solid var(--line); border-radius:6px; padding:6px 10px; font:12px monospace; }
  #content_files.bad { border-color:var(--bad); }
  #notes { width:100%; background:var(--bg); color:var(--text);
           border:1px solid var(--line); border-radius:6px; padding:6px 10px; }
  #actions { display:flex; justify-content:flex-end; gap:10px; margin-top:10px; }
  button { border:0; border-radius:8px; padding:10px 18px; font-size:13px; font-weight:600; cursor:pointer; }
  #copyBtn { background:transparent; color:var(--dim); border:1px solid var(--line); }
  #buildBtn { background:var(--accent); color:#0a0e18; }
  #buildBtn:disabled { opacity:.4; cursor:not-allowed; }
  .toast { position:fixed; bottom:18px; left:50%; transform:translateX(-50%); background:var(--panel);
           border:1px solid var(--line); padding:10px 16px; border-radius:8px; font-size:13px; display:none; }
</style>
</head>
<body>
<header>
  <h1>HTML SLIDES — Lesson Deck Picker</h1>
  <span class="from-opencode" id="fromOpencode">waiting for your submission (opencode is watching)</span>
  <span class="badge" id="json-library-badge"></span>
</header>
<main>
  <nav id="rail">
    <input id="q" type="search" placeholder="Search templates">
    <h2>Scheme</h2><div data-filter="scheme"></div>
    <h2>Density</h2><div data-filter="density"></div>
    <h2>Formality</h2><div data-filter="formality"></div>
    <h2>Tags</h2><div data-filter="occasion"></div>
    <div class="count" id="count"></div>
  </nav>
  <section id="grid"></section>
</main>
<footer>
  <div id="ribbon">Select a template to begin.</div>
  <div class="row">
    <div class="field"><span>Slide count</span>
      <div class="row">
        <label><input id="autoCount" type="checkbox"> auto</label>
        <input id="countN" type="number" min="3" max="30" value="12" disabled>
      </div>
    </div>
    <div class="field"><span>Density</span>
      <select id="density">
        <option value="auto">auto</option><option value="sparse">sparse</option>
        <option value="balanced" selected>balanced</option><option value="dense">dense</option>
      </select>
    </div>
  </div>
  <div class="field" style="margin-top:8px"><span>Content files (one absolute path per line)</span>
    <textarea id="content_files" placeholder="D:\lessons\Week-1-Notebook.html"></textarea>
  </div>
  <div class="field" style="margin-top:8px"><span>Extra notes (optional)</span>
    <input id="notes" placeholder="e.g. keep section dividers minimal">
  </div>
  <div id="actions">
    <button id="copyBtn">Copy selection</button>
    <button id="buildBtn" disabled>BUILD DECK</button>
  </div>
</footer>
<div class="toast" id="toast"></div>
<script src="library.json.js"></script>
```

*Script (entire `<script>…</script>` tail, verbatim):*

```html
<script>
(function () {
    const T = window.LIBRARY.templates;
    const $ = s => document.querySelector(s);
    const grid = $('#grid'), rail = $('#rail');

    $('#json-library-badge').textContent =
        'templates: ' + T.length + ' · library refreshed ' + window.LIBRARY.updated_at.slice(0, 10);
    if (new URLSearchParams(location.search).get('from') === 'opencode')
        $('#fromOpencode').style.display = 'inline-block';

    let recalled = localStorage.getItem('picker.lastTemplate') || '';

    // filters: value lists derived from data (moods intentionally absent);
    // occasion/scheme/density/formality only
    const values = k => [...new Set(
        T.map(t => Array.isArray(t[k]) ? t[k] : (t[k] == null ? [] : [t[k]]))
            .flat().filter(Boolean).sort())];
    for (const k of ['scheme', 'density', 'formality', 'occasion']) {
        const box = rail.querySelector('[data-filter="' + k + '"]');
        for (const v of values(k)) {
            const lab = document.createElement('label');
            lab.className = 'chip';
            const cb = document.createElement('input');
            cb.type = 'checkbox'; cb.dataset.k = k; cb.value = v;
            lab.appendChild(cb);
            lab.appendChild(document.createTextNode(' ' + v));
            box.appendChild(lab);
        }
    }

    function activeFilters() {
        const f = {};
        rail.querySelectorAll('input[type=checkbox]:checked')
            .forEach(c => { (f[c.dataset.k] = f[c.dataset.k] || []).push(c.value); });
        return f;
    }

    function passes(t, f, q) {
        if (q && !((t.name + ' ' + t.tagline).toLowerCase().includes(q))) return false;
        for (const k of ['scheme', 'density', 'formality'])
            if (f[k] && !f[k].includes(t[k])) return false;
        if (f.occasion && !f.occasion.some(v => (t.occasion || []).includes(v))) return false;
        return true;
    }

    function cards() {
        const q = $('#q').value.trim().toLowerCase();
        const f = activeFilters();
        grid.innerHTML = '';
        let n = 0;
        for (const t of T) {
            if (!passes(t, f, q)) continue;
            const c = document.createElement('div');
            c.className = 'card' + (t.slug === recalled ? ' sel' : '');
            c.dataset.templateCard = t.slug;
            const img = document.createElement('img');
            img.loading = 'lazy';
            img.src = 'screenshots/' + encodeURIComponent(t.slug) + '.png';
            const meta = document.createElement('div');
            meta.className = 'meta';
            meta.innerHTML = '<div class="name"></div><div class="tag"></div>';
            meta.querySelector('.name').textContent = t.name;
            meta.querySelector('.tag').textContent = t.tagline;
            c.appendChild(img); c.appendChild(meta);
            c.onclick = () => { recalled = t.slug; localStorage.setItem('picker.lastTemplate', t.slug); cards(); ribbon(); revalidate(); };
            grid.appendChild(c);
            n++;
        }
        $('#count').textContent = n + ' / ' + T.length;
    }

    function ribbon() {
        const t = T.find(x => x.slug === recalled);
        const r = $('#ribbon');
        if (t) { r.innerHTML = 'SELECTED: <b></b> — <span></span>'; r.querySelector('b').textContent = t.name; r.querySelector('span').textContent = t.tagline; }
        else r.textContent = 'Select a template to begin.';
    }

    const PATH_RE = /^[a-zA-Z]:\\.*/;
    const isPathLike = line => PATH_RE.test(line.trim()) || line.trim().startsWith('\\\\');
    function paths() { return $('#content_files').value.split(/\r?\n/).map(s => s.trim()).filter(Boolean); }
    function revalidate() {
        const list = paths();
        const bad = list.length > 0 && list.some(p => !isPathLike(p));
        $('#content_files').classList.toggle('bad', bad);
        $('#buildBtn').disabled = !(recalled && list.length > 0 && !bad);
    }
    $('#content_files').addEventListener('input', revalidate);
    $('#autoCount').onchange = () => { $('#countN').disabled = $('#autoCount').checked; };

    function payload() {
        return {
            template: recalled,
            slide_count: $('#autoCount').checked ? 'auto' : (Number($('#countN').value) || 12),
            density: $('#density').value,
            content_files: paths(),
            notes: $('#notes').value.trim()
        };
    }
    function toast(msg, long) {
        const t = $('#toast');
        t.textContent = msg; t.style.display = 'block';
        clearTimeout(t._h);
        t._h = setTimeout(() => { t.style.display = 'none'; }, long ? 8000 : 3000);
    }

    let dirDB = null;
    function savedDir() {
        return new Promise(res => {
            const open = indexedDB.open('picker', 1);
            open.onupgradeneeded = () => open.result.createObjectStore('kv');
            open.onsuccess = () => {
                dirDB = open.result;
                const req = dirDB.transaction('kv').objectStore('kv').get('dir');
                req.onsuccess = () => res(req.result || null);
                req.onerror = () => res(null);
            };
            open.onerror = () => res(null);
        });
    }
    function keepDir(dir) {
        const tx = dirDB.transaction('kv', 'readwrite');
        tx.objectStore('kv').put(dir, 'dir');
    }
    async function persist(dir, text) {
        const perm = await dir.queryPermission({ mode: 'readwrite' });
        if (perm !== 'granted' && (await dir.requestPermission({ mode: 'readwrite' })) !== 'granted') return false;
        const file = await dir.getFileHandle('selection.json', { create: true });
        const w = await file.createWritable();
        await w.write(text); await w.close();
        return true;
    }
    async function writeJson() {
        const text = JSON.stringify(payload(), null, 2);
        try {
            const remembered = await savedDir();
            if (remembered && await persist(remembered, text)) {
                toast('✓ sent to selection.json'); finish(); return;
            }
            const granted = await window.showDirectoryPicker({ id: 'picker-out', mode: 'readwrite' });  // ONE-TIME folder grant
            if (await persist(granted, text)) { keepDir(granted); toast('✓ sent to selection.json'); finish(); return; }
            throw new Error('permission denied');
        } catch (e) {
            await navigator.clipboard.writeText(text);
            toast('silent save unavailable — JSON copied to clipboard instead', true);
        }
    }
    function finish() {
        if (new URLSearchParams(location.search).get('from') === 'opencode')
            toast('opencode is reading selection.json — you can keep this open or close it', true);
    }

    $('#buildBtn').onclick = writeJson;
    $('#copyBtn').onclick = async () => {
        await navigator.clipboard.writeText(JSON.stringify(payload(), null, 2));
        toast('selection JSON copied');
    };

    cards(); ribbon(); revalidate();
})();
</script>
</body>
</html>
```

Delete the stray draft line `const pathOk = line => /^[a-zA-Z]:\\/ || ...` — keep only `PATH_RE`/`isPathLike`. (`showDirectoryPicker` exists in Edge/Chrome ≥ 86 — fine here.)

- [ ] **Step 4: Run test, verify it passes**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-picker-dom.ps1`
Expected: `all 5 checks passed` (cards = 34), exit 0.

- [ ] **Step 5: Manual interactive pass (headless can't click — verify every item)**

Open `picker\picker.html` normally:
1. Search "daisy" → 1 card; scheme=dark → only dark cards; live count updates.
2. Click a card → ring+check+ribbon; reopen (reload) → still selected (localStorage).
3. "auto" checkbox disables number input; payload `"slide_count":"auto"` (check via Copy selection → clipboard).
4. Content line `hello.txt` (no drive prefix) → textarea red + BUILD DECK disabled; `D:\x.html` → re-enabled.
5. First BUILD DECK → one-time folder grant (point at picker folder) → file written; second submit → silent write.
6. `?from=opencode` → green banner. Notes → JSON.

- [ ] **Step 6: Commit**

```bash
git add picker/picker.html picker/tests/test-picker-dom.ps1
git commit -m "feat(picker): single-file GUI with filter rail, screenshot grid, json save"
```

---

### Task 5: picker.cmd + shortcuts + browser resolution

**Files:**
- Modify: `picker\install.ps1` (append sections 4–5)
- Create: `picker\picker.cmd`
- Create: `picker\tests\test-shortcuts.ps1`

**Interfaces:**
- Consumes: `picker\picker.html` (Task 4), `picker\watcher.ps1` (Task 3).
- Produces: `picker\web-browser.txt` (resolved Edge→Chrome exe path); `picker\picker.cmd` (opens app window + hidden watcher, `TimeoutSec 3600`); Desktop + Start Menu `HTML Slides Picker.lnk` → `picker.cmd`.

- [ ] **Step 1: Write failing test (picker/tests/test-shortcuts.ps1)**

```powershell
$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Assert($cond, $name) {
    if ($cond) { Write-Host "PASS: $name"; $script:pass++ }
    else       { Write-Host "FAIL: $name"; $script:fail++ }
}
$root       = Split-Path (Split-Path $PSScriptRoot)
$picker     = Join-Path $root 'picker'
$browserTxt = Join-Path $picker 'web-browser.txt'
Assert (Test-Path $browserTxt) 'web-browser.txt exists'
if (Test-Path $browserTxt) {
    $browser = (Get-Content $browserTxt -Raw).Trim()
    Assert (Test-Path $browser) "browser exe exists ($browser)"
}
$ws = New-Object -ComObject WScript.Shell
foreach ($loc in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
    $lnkPath = Join-Path $loc 'HTML Slides Picker.lnk'
    Assert (Test-Path $lnkPath) "shortcut exists: $lnkPath"
    if (Test-Path $lnkPath) {
        $s = $ws.CreateShortcut($lnkPath)
        Assert ($s.TargetPath -eq (Join-Path $picker 'picker.cmd')) "shortcut targets picker.cmd: $lnkPath"
    }
}
$cmd = Get-Content (Join-Path $picker 'picker.cmd') -Raw
Assert ($cmd -match 'watcher\.ps1') 'picker.cmd starts watcher'
Assert ($cmd -match '--app=') 'picker.cmd opens app window'
if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0
```

- [ ] **Step 2: Run test, verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-shortcuts.ps1`
Expected: `FAIL: web-browser.txt exists`, exit 1.

- [ ] **Step 3: Implement (append to install.ps1; create picker.cmd)**

Append to `picker\install.ps1` (AFTER section 3; `$edge` already in scope; do not reuse it for the GUI, resolve separately Edge-first):

```powershell
# ---------- section 4+5: browser resolve, web-browser.txt, shortcuts ----------
$chromeKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue
$chrome = if ($chromeKey) { $chromeKey.'(default)' } else { $null }
$guiBrowser = (@($edge, $chrome) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
if (-not $guiBrowser) { throw 'Neither Edge nor Chrome found via App Paths registry keys' }
Set-Content (Join-Path $PSScriptRoot 'web-browser.txt') -Value $guiBrowser -Encoding UTF8
if ($SkipShortcuts) { Write-Host 'shortcuts skipped (-SkipShortcuts)'; return }

$ws = New-Object -ComObject WScript.Shell
$target = Join-Path $PSScriptRoot 'picker.cmd'
foreach ($loc in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
    $lnk = $ws.CreateShortcut((Join-Path $loc 'HTML Slides Picker.lnk'))
    $lnk.TargetPath = $target
    $lnk.WorkingDirectory = $PSScriptRoot
    $lnk.IconLocation = "$guiBrowser,0"
    $lnk.Save()
    Write-Host "shortcut installed: $loc\HTML Slides Picker.lnk"
}
```

Create `picker\picker.cmd`:

```bat
@echo off
setlocal enabledelayedexpansion
if not exist "%~dp0web-browser.txt" (
  echo No web-browser.txt - run picker\install.ps1 first.
  pause
  exit /b 1
)
for /f "usebackq delims=" %%i in ("%~dp0web-browser.txt") do set "BROWSER=%%i"
set "U=%~dp0picker.html"
set "U=!U:\=/!"
start "" "%BROWSER%" --app="file:///!U!"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0watcher.ps1" -TimeoutSec 3600
endlocal
```

- [ ] **Step 4: Run installer + test**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File picker\install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-shortcuts.ps1
```

Expected: `all N checks passed`; exit 0.

- [ ] **Step 5: Manual smoke**

Double-click Desktop "HTML Slides Picker": app-mode window (no address bar) opens with the GUI; Task Manager shows a `watcher.ps1` process. Close and reopen: both resurrection works.

- [ ] **Step 6: Commit**

```bash
git add picker/install.ps1 picker/picker.cmd picker/tests/test-shortcuts.ps1
git commit -m "feat(picker): app-mode launcher + desktop/start-menu shortcuts"
```

---

### Task 6: SKILL.md rewrite (picker-first workflow)

**Files:**
- Modify: `SKILL.md` (replace `## Workflow` steps; keep Step 0 routing, Content mapping, USER RULE 30px floor, deliver-step; extend Common Mistakes)

**Interfaces:**
- Consumes: selection.json schema; watcher.ps1 exit contract (0 = ready, 3 = timeout → ask user; the ONLY allowed ask).
- Produces: markdown below (preserve meaning verbatim; polish wording is allowed within these semantics).

- [ ] **Step 1: Replace workflow steps**

Replace the `## Workflow` section content with exactly this five-step block (keep the `####`-less style of the file):

```markdown
**Step 1 — Launch the picker and read selection.json.**
If the user did not already come from the picker GUI:
```powershell
$browser = (Get-Content "C:\Users\aclco\.claude\skills\html-slides\picker\web-browser.txt" -Raw).Trim()
Start-Process $browser -ArgumentList '--app=file:///C:/Users/aclco/.claude/skills/html-slides/picker/picker.html?from=opencode'
```
Wait for the watcher to report the selection:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\aclco\.claude\skills\html-slides\picker\watcher.ps1" -NotifyOnly -TimeoutSec 3600
```
Exit 0 → read `picker\selection.json` now. Exit 3 → timeout: ask the user in chat (this is the ONLY allowed fallback ask).
Fixed context (never asked, never surfaced): occasion = classroom discussion; audience = high school; mood is irrelevant (the template choice covers it); deck titles follow the source document titles; extra slides only when content earns them.
Only if a required JSON field is missing/invalid: ask — otherwise trust the JSON.

**Step 2 — Extract the content.**
For every path in `content_files`, read the source. Organize slides from the source itself: one idea per slide; headlines presentation-ready and true to the source's titles; slide count and density from the JSON (`"auto"` → your call). If a path is missing, report which file was readable/missing and continue with what resolved.

**Step 3 — Build the deck in the chosen template.**
Import: `picker\repo` (refresh with `picker\install.ps1` ONLY if `templates.json` is older than the user wants or `repo` is missing). Locate `template`'s slug in `picker\templates.json`; if mapped to a missing slug, name the nearest equivalent based on scheme/density/formality and SAY you substituted. In the chosen template: follow the repo's own AGENTS.md §3–§5 — preserve fonts, palette, layout grid, slide-level CSS classes, decorative elements, navigation runtime; replace all placeholder content; duplicate the most appropriate layout for extra slides and update `NN / TT` page numbers; design missing layouts with the template's own design system.

**Step 4 — Auto font-size fit pass.** *(unchanged from the previous version — 1920×1080 stage overflow logic, incl. the persistent 30px floor for EVERY text element and headless-screenshot verification on the densest slides)*

**Step 5 — Deliver.** *(unchanged from the previous version: open the final deck in the browser, send the absolute file path on its own line plus one line on which template was picked and why, and any caveats — e.g. a template substitution or a from-scratch designed slide).*
```

- [ ] **Step 2: Append to Common Mistakes**

```
- Asking any question the picker GUI already answered — `selection.json` is the source of truth
- Reading `selection.json` before the watcher exits 0 — a mid-write JSON is the classic failure mode
```

- [ ] **Step 3: Consistency check**

```powershell
Select-String -Path SKILL.md -Pattern 'occasion|mood|previews|Step 6|Step 7'
```
Expected: only fixed-context mentions from the new Step 1 (occasion); no `Step 6`/`Step 7`/`previews` remain (except inside Common Mistakes if deliberately kept).

- [ ] **Step 4: Commit**

```bash
git add SKILL.md
git commit -m "docs(skill): picker-first workflow replaces preview round-trip"
```

---

### Task 7: End-to-end verification (both flows)

**Files:** none created; verification only.

- [ ] **Step 1: Run the full automated suite**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-library.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-screenshots.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-watcher.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-picker-dom.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File picker\tests\test-shortcuts.ps1
```
Expected: all exit 0.

- [ ] **Step 2: Flow A (opencode-first)**

Live opencode session: "create html slides from the picker". Confirm: GUI opens (green banner); choose daisy-days / 12 / balanced / one real lesson file; BUILD DECK; watcher exits 0 promptly; deck builds in daisy-days; ZERO questions asked mid-build; 30px floor holds on the densest slide (headless screenshot); deck opens.

- [ ] **Step 3: Flow B (standalone double-click)**

Close opencode. Double-click Desktop shortcut → picker window + hidden watcher → submit → `opencode run` visible terminal fires; deck is delivered. Verify `selection.json` still on disk afterwards.

- [ ] **Step 4: Finalize**

Fix anything that failed and rerun until green. Then:

```bash
git add -A
git commit -m "test(picker): both flows verified end to end"
```

---

## Self-Review (done)

- **Spec coverage:** installer→ T1/T2/T5; GUI→ T4; watcher→ T3; SKILL.md→ T6; error handling→ T2 threshold rows, T3 hash+mutex+soft-exit, T4 clipboard fallback/validation/notice, T6 timeout-fallback ask; fixed-context constants live in Global Constraints + T4 header/T1 field names; both flows verified in T7. Selection-freshness (`templates.json` age badge) in T4; substitution-on-missing-slug in T6 Step 3.
- **Placeholders:** none — every scripted step contains runnable code; the T4 deliverable is provided verbatim in full.
- **Name consistency:** `window.LIBRARY`, `data-template-card`, `recalled`, PATH_RE / isPathLike, `-NotifyOnly`, exit codes 0/3, `picker.lastTemplate`, IndexedDB `picker`/`kv`/`dir` — checked identical across T3/T4/T5/T6.
- **Deliberate derivations:** path-format-only validation (spec deviation) documented in Global Constraints.

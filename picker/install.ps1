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
# BOM-less UTF-8: picker.app's fetch and the for /f reader choke on a BOM; PS 5.1 Set-Content -Encoding UTF8 emits one
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'templates.json'),  $json, (New-Object System.Text.UTF8Encoding $false))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'library.json.js'), ('window.LIBRARY = ' + $json + ';' + [Environment]::NewLine), (New-Object System.Text.UTF8Encoding $false))

Write-Host 'install: sections 1-2 done (templates.json + library.json.js)'

# ---------- section 3: first-three-slides captures via Chrome headless (4 parallel jobs) ----------
$ssDirPath = Join-Path $PSScriptRoot 'screenshots'
New-Item -ItemType Directory -Force -Path $ssDirPath | Out-Null
$chromeKey0 = Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue
if (-not $chromeKey0) { $chromeKey0 = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue }
$chrome = if ($chromeKey0) { $chromeKey0.'(default)' } else { $null }
if (-not $chrome -or -not (Test-Path $chrome)) { throw 'Chrome (chrome.exe) not found via App Paths keys (HKCU/HKLM)' }

# one tile: inject a scroll-snap killer + scrollTop jump, chrome-headless shot;
# --screenshot blocks until the PNG is fully on disk, so a size check suffices after
$captureScript = {
    param($chrome, $ssDir, $repo, $slugList, $force, $budget, $onlyTiles)
    # Start-Job stringify-fuzzes arguments ([bool]$true arrives as the string
    # '[bool]True'): extract the payload token for every crossed-boundary arg
    $force = "$force" -match 'True$'
    if ($budget -notmatch '^\d+$') { $budget = [regex]::Match("$budget", '\d+').Value }
    $budget = [int]$budget
    $onlyTiles = @($onlyTiles | ForEach-Object { [regex]::Match("$_", '\d+').Value } | Where-Object { $_ })
    # per-job throwaway profile: no singleton contention between the 4 jobs,
    # and webfonts stay warm across a chunk's sequential tiles
    $udd = Join-Path ([IO.Path]::GetTempPath()) ('slides-capture-' + $PID)
    New-Item -ItemType Directory -Force -Path $udd | Out-Null
    $bad = @()
    foreach ($slug in @($slugList)) {
        $src = Join-Path $repo ('templates\' + $slug + '\template.html')
        if (-not (Test-Path $src)) { $bad += ('no template.html: ' + $slug); continue }
        $html = Get-Content $src -Raw -Encoding UTF8
        $tiles = 0
        for ($i = 1; $i -le 3; $i++) {
            $png = Join-Path $ssDir ($slug + '-' + $i + '.png')
            if (@($onlyTiles).Count -gt 0 -and @($onlyTiles) -notcontains $i) {
                if ((Test-Path $png) -and ((Get-Item $png).Length -gt 20KB)) { $tiles++ }
                else { $bad += ('capture failed: ' + $slug + '-' + $i) }
                continue
            }
            $upToDate = (Test-Path $png) -and ((Get-Item $png).Length -gt 20KB)
            if ($upToDate -and -not $force) { $tiles++; continue }
            # inject: kill scroll-snap so scrollTop holds, jump to slide i on load
            $inject = '<style>html,body{margin:0} .slides-container{scroll-snap-type:none !important;' `
                + 'scroll-behavior:auto !important; overflow-y:hidden !important}' `
                + '</style><script>window.addEventListener("load",function(){' `
                + 'var c=document.querySelector(".slides-container"); if(c){c.scrollTop=' `
                + (1080 * ($i - 1)) + ';}});</script>'
            $marker = '</body>'
            $idx = $html.LastIndexOf($marker)
            if ($idx -lt 0) { $bad += ('no </body> to inject: ' + $slug); break }
            # <deck-stage> decks slide via JS (slides opacity:0 until activated) and don't
            # scroll: deep-link via the 1-indexed #<int> hash its _restoreIndex() reads at mount
            $hash = if ($html -match '<deck-stage') { '#' + $i } else { '' }
            # temp copy lives in the template's own directory so relative assets
            # (deck-stage.js) still resolve; deleted in the finally below
            $tmp = Join-Path (Split-Path $src) ('~' + $slug + '-' + $i + '.html')
            Set-Content -Path $tmp -Value ($html.Substring(0, $idx) + $inject + $html.Substring($idx)) -Encoding UTF8
            try {
                # PS 5.1: native stderr + $ErrorActionPreference='Stop' + 2>&1 still emits
                # record noise; relax EAP across the Chrome call only
                $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
                # NOTE: 2>$null silently kills the screenshot write on PS 5.1 (stderr
                # handle never read); drain stderr through 2>&1 instead
                $noise = & $chrome --headless --disable-gpu --hide-scrollbars `
                    --default-background-color=FFFFFFFF "--virtual-time-budget=$budget" `
                    '--window-size=1920,1080' "--screenshot=$png" "--user-data-dir=$udd" `
                    ('file:///' + ($tmp -replace '\\','/') + $hash) 2>&1 | Out-String
                $ErrorActionPreference = $prevEap
            } finally {
                Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            }
            if ((Test-Path $png) -and ((Get-Item $png).Length -gt 20KB)) { $tiles++ }
            else { $bad += ('capture failed: ' + $slug + '-' + $i) }
        }
        # legacy single-page capture: delete only once the slug's tiles are all fresh
        if ($tiles -eq 3) {
            $legacy = Join-Path $ssDir ($slug + '.png')
            if (Test-Path $legacy) { Remove-Item $legacy -Force }
        }
    }
    Remove-Item $udd -Recurse -Force -ErrorAction SilentlyContinue
    return $bad
}

# 4 concurrent capture jobs (round-robin slug split), each sequential within its chunk
$allSlugs = @($templates | ForEach-Object { $_.slug })
$jobs = @()
for ($c = 0; $c -lt 4; $c++) {
    $slugs = @()
    for ($n = $c; $n -lt $allSlugs.Count; $n += 4) { $slugs += $allSlugs[$n] }
    if ($slugs.Count -eq 0) { continue }
    $jobs += Start-Job -Name "capture-$c" -ScriptBlock $captureScript `
        -ArgumentList $chrome, $ssDirPath, $repo, $slugs, [bool]$Force, 5000, @()
}
Wait-Job $jobs -Timeout 600 | Out-Null
$bad = @()
foreach ($j in $jobs) {
    $bad += @(Receive-Job -Job $j -ErrorAction SilentlyContinue | Where-Object { $_ })
    Remove-Job $j -Force
}

# single retry pass: any missing/tiny tile re-captured once at the 15s budget
# (fonts warming; a tile < 20 KB is the only observed under-budget failure)
foreach ($t in $templates) {
    $stale = @()
    foreach ($i in 1..3) {
        $png = Join-Path $ssDirPath ($t.slug + '-' + $i + '.png')
        if (-not (Test-Path $png) -or ((Get-Item $png).Length -le 20KB)) { $stale += $i }
    }
    if ($stale.Count -eq 0) { continue }
    $slug = $t.slug
    Write-Host "screenshots: retrying $slug tiles $($stale -join ',') at the 15s budget"
    $bad += @(& $captureScript $chrome $ssDirPath $repo @($slug) $true 15000 @($stale))
}
if ($bad.Count -gt 0) { throw ($bad -join '; ') }
Write-Host "screenshots: 3 tiles per template for $($templates.Count) templates"

# ---------- section 4+5: browser resolve, web-browser.txt, shortcuts ----------
# probe HKCU BEFORE HKLM: per-user Chrome installs only register under HKCU
function Resolve-Chrome {
    foreach ($hive in 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
                        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe') {
        $key = Get-ItemProperty $hive -ErrorAction SilentlyContinue
        $exe = $key.'(default)'
        if ($exe -and (Test-Path $exe)) { return $exe }
    }
    return $null
}
$guiBrowser = Resolve-Chrome
if (-not $guiBrowser) { throw 'Chrome (chrome.exe) not found via App Paths registry keys (HKCU/HKLM)' }
# BOM-less UTF-8: picker.cmd's for /f is not BOM-aware (PS 5.1 Set-Content -Encoding UTF8 emits a BOM)
$browserTxt = Join-Path $PSScriptRoot 'web-browser.txt'
[IO.File]::WriteAllText($browserTxt, $guiBrowser + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding $false))
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

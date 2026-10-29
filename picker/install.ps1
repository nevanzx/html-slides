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

Write-Host 'install: sections 1-2 done (templates.json + library.json.js)'

# ---------- section 3: title-slide screenshots via Chrome headless ----------
$ssDir = Join-Path $PSScriptRoot 'screenshots'
New-Item -ItemType Directory -Force -Path $ssDir | Out-Null
$chromeKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue
$chrome = $chromeKey.'(default)'
if (-not $chrome -or -not (Test-Path $chrome)) { throw 'Chrome (chrome.exe) not found via App Paths registry key' }

$bad = @()
foreach ($t in $templates) {
    $png  = Join-Path $ssDir ($t.slug + '.png')
    $html = Join-Path $repo ('templates\' + $t.slug + '\template.html')
    $upToDate = (Test-Path $png) -and (Get-Item $png).Length -gt 20KB
    if ($upToDate -and -not $Force) { continue }
    if (-not (Test-Path $html)) { $bad += ('no template.html: ' + $t.slug); continue }
    $url = 'file:///' + ($html -replace '\\', '/')
    # PS 5.1: native stderr + $ErrorActionPreference='Stop' + 2>$null still throws;
    # relax EAP across the Chrome call only (benign Chromium stderr noise)
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $chrome --headless --disable-gpu --hide-scrollbars --default-background-color=FFFFFFFF `
        '--window-size=1920,1080' '--virtual-time-budget=15000' "--screenshot=$png" $url 2>$null | Out-Null
    $ErrorActionPreference = $prevEap
    for ($i = 0; $i -lt 20; $i++) {
        if ((Test-Path $png) -and (Get-Item $png).Length -gt 20KB) { break }
        Start-Sleep -Milliseconds 500
    }
    if ((-not (Test-Path $png)) -or (Get-Item $png).Length -le 20KB) { $bad += ('capture failed: ' + $t.slug) }
}
if ($bad.Count -gt 0) { throw ($bad -join '; ') }
Write-Host "screenshots: ready for $($templates.Count) templates"

# ---------- section 4+5: browser resolve, web-browser.txt, shortcuts ----------
$chromeKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue
$chrome = if ($chromeKey) { $chromeKey.'(default)' } else { $null }
$guiBrowser = if ($chrome -and (Test-Path $chrome)) { $chrome } else { $null }
if (-not $guiBrowser) { throw 'Chrome (chrome.exe) not found via App Paths registry key' }
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

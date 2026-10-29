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

# ---------- section 3: title-slide screenshots via Edge headless ----------
$ssDir = Join-Path $PSScriptRoot 'screenshots'
New-Item -ItemType Directory -Force -Path $ssDir | Out-Null
$edgeKey = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue
$edge = $edgeKey.'(default)'
if (-not $edge -or -not (Test-Path $edge)) { throw 'Edge (msedge.exe) not found via App Paths key' }

$bad = @()
foreach ($t in $templates) {
    $png  = Join-Path $ssDir ($t.slug + '.png')
    $html = Join-Path $repo ('templates\' + $t.slug + '\template.html')
    $upToDate = (Test-Path $png) -and (Get-Item $png).Length -gt 20KB
    if ($upToDate -and -not $Force) { continue }
    if (-not (Test-Path $html)) { $bad += ('no template.html: ' + $t.slug); continue }
    $url = 'file:///' + ($html -replace '\\', '/')
    # PS 5.1: native stderr + $ErrorActionPreference='Stop' + 2>$null still throws;
    # relax EAP across the Edge call only (benign Chromium stderr noise)
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $edge --headless --disable-gpu --hide-scrollbars --default-background-color=FFFFFFFF `
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

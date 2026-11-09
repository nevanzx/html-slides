param([switch]$Force)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$repo = Join-Path $root 'repo'
$localTemplates = Join-Path $root 'local-templates'
$localIndexPath = Join-Path $root 'local-index.json'

# ---------- 1. copy locally authored templates into the repo clone ----------
Get-ChildItem -LiteralPath $localTemplates -Directory | ForEach-Object {
    $dest = Join-Path $repo ('templates\' + $_.Name)
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Get-ChildItem -LiteralPath $_.FullName -File | Copy-Item -Destination $dest -Force
}
Write-Host 'sync: local templates copied into repo/templates'

# ---------- 2. merged index -> templates.json + library.json.js ----------
$index = Get-Content (Join-Path $repo 'index.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$localIndex = Get-Content $localIndexPath -Raw -Encoding UTF8 | ConvertFrom-Json
$merged = [System.Collections.ArrayList]::new()
foreach ($t in @($index.templates)) { [void]$merged.Add($t) }
$have = @($merged | ForEach-Object { $_.slug })
foreach ($t in @($localIndex.templates)) {
    if ($have -notcontains $t.slug) { [void]$merged.Add($t) }
}
$templates = @(
    $merged | ForEach-Object {
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
[IO.File]::WriteAllText((Join-Path $root 'templates.json'), $json, (New-Object System.Text.UTF8Encoding $false))
[IO.File]::WriteAllText((Join-Path $root 'library.json.js'), ('window.LIBRARY = ' + $json + ';' + [Environment]::NewLine), (New-Object System.Text.UTF8Encoding $false))
Write-Host ('sync: {0} templates total ({1} local)' -f $templates.Count, @($localIndex.templates).Count)

# ---------- 3. capture first three tiles per local template (deck-stage #hash) ----------
$chrome = $null
foreach ($hive in 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe',
                  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe') {
    $key = Get-ItemProperty $hive -ErrorAction SilentlyContinue
    if ($key -and $key.'(default)' -and (Test-Path $key.'(default)')) { $chrome = $key.'(default)'; break }
}
if (-not $chrome) { throw 'chrome.exe not found via App Paths keys' }
$ss = Join-Path $root 'screenshots'
New-Item -ItemType Directory -Force -Path $ss | Out-Null
foreach ($t in @($localIndex.templates)) {
    $src = Join-Path $repo ('templates\' + $t.slug + '\template.html')
    for ($i = 1; $i -le 3; $i++) {
        $png = Join-Path $ss ($t.slug + '-' + $i + '.png')
        if ((Test-Path $png) -and -not $Force) { continue }
        $url = 'file:///' + ($src -replace '\\', '/') + '#' + $i
        $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        & $chrome --headless=new --disable-gpu --hide-scrollbars --window-size=1920,1080 `
            --virtual-time-budget=6000 "--screenshot=$png" "$url" 2>&1 | Out-Null
        $ErrorActionPreference = $prevEap
        if (-not (Test-Path $png)) { throw ('capture failed: ' + $t.slug + '-' + $i) }
        Write-Host ('sync: shot ' + (Split-Path $png -Leaf))
    }
}
Write-Host 'sync: done'

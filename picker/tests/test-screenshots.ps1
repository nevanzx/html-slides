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

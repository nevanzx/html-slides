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

$missing = @(); $tiny = @(); $totalTiles = 0
foreach ($t in $json.templates) {
    foreach ($i in 1..3) {
        $totalTiles++
        $png = Join-Path $ssDir ($t.slug + '-' + $i + '.png')
        if (-not (Test-Path $png)) { $missing += "$($t.slug)-$i"; continue }
        if ((Get-Item $png).Length -lt 20KB) { $tiny += "$($t.slug)-$i" }
    }
    $legacy = Join-Path $ssDir ($t.slug + '.png')
    if (Test-Path $legacy) { $tiny += "$($t.slug)-legacy" }
}
Assert ($missing.Count -eq 0) ("no missing tiles" + $(if ($missing.Count) { ': ' + ($missing -join ',') }))
Assert ($tiny.Count -eq 0)   ("no blank/tiny/legacy captures" + $(if ($tiny.Count) { ': ' + ($tiny -join ',') }))
Assert ($totalTiles -eq $json.templates.Count * 3) ("tile count = 3x templates ($totalTiles)")
if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"

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

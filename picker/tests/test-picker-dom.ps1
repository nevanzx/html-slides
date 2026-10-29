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

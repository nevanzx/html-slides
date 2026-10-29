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
$html = Join-Path $root 'picker\picker.html'
Assert (Test-Path $html) 'picker.html exists'
if ($fail -gt 0) { exit 1 }

$dom = & $chrome --headless --disable-gpu --virtual-time-budget=4000 --dump-dom ('file:///' + ($html -replace '\\','/')) | Out-String
Assert ($dom -match 'data-template-card=') 'grid renders template cards'
$cardCount = ([regex]::Matches($dom, 'data-template-card=')).Count
Assert ($cardCount -ge 30) "cards rendered >= 30 (got $cardCount)"
Assert ($dom -match 'BUILD DECK') 'build-deck button rendered'
Assert ($dom -match 'json-library-badge') 'library badge rendered'
Assert ($dom -match 'content_files') 'content files textarea rendered'
Assert (-not ($dom -match 'data-filter="occasion"')) 'occasion filter absent'
Assert (-not ($dom -match '<footer')) 'no footer element'
Assert ($dom -match '\-1\.png') 'thumbnails use tile-1 captures'
Assert ($dom -match 'id="shotModal"') 'modal shell present'
Assert ($dom -match 'data-modal-shot') 'modal has 3 image slots'
Assert ($dom -match 'id="modalSelect"') 'modal SELECT button present'
if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0

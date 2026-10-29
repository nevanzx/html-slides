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
if ($fail -gt 0) { exit 1 }

function New-StatusFixture([string]$statusJs) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('picker-status-' + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Copy-Item (Join-Path $root 'picker\picker.html')       $tmp
    Copy-Item (Join-Path $root 'picker\library.json.js')   $tmp
    if ($statusJs) { Set-Content -Path (Join-Path $tmp 'status.js') -Value $statusJs -Encoding ASCII }
    return $tmp
}
function Get-StatusDom([string]$fixture) {
    $html = Join-Path $fixture 'picker.html'
    return (& $chrome --headless --disable-gpu --virtual-time-budget=5000 --dump-dom ('file:///' + ($html -replace '\\','/')) | Out-String)
}
function Remove-Fixture([string]$fixture) { Remove-Item -Recurse -Force $fixture }

$doneJs = @'
window.__DECK_STATUS = { state: "done", step: "deliver", message: "Deck built from status test", output: "C:\\Temp\\status-demo\\Week-1-deck.html", updated_at: new Date().toISOString() };
'@
$runningJs = @'
window.__DECK_STATUS = { state: "running", step: "build", message: "Building template demo", updated_at: new Date().toISOString() };
'@
$errorJs = @'
window.__DECK_STATUS = { state: "error", step: "build", message: "template repo missing", updated_at: new Date().toISOString() };
'@
$waitingJs = @'
window.__DECK_STATUS = { state: "waiting", step: "read-selection", message: "picked up selection.json", updated_at: new Date().toISOString() };
'@
$staleJs = @'
window.__DECK_STATUS = { state: "done", step: "deliver", message: "old run", output: "C:\\Temp\\old\\deck.html", updated_at: "2020-01-01T00:00:00.000Z" };
'@

# 1. done state: panel exists, state marked, Open deck link with slashed file URL
$fx = New-StatusFixture $doneJs; $dom = Get-StatusDom $fx
Assert ($dom -match 'id="statusScreen"')                          'status screen exists in markup'
Assert ($dom -match 'data-status-state="done"')                   'done state marked on panel'
Assert ($dom -match 'id="statusOpenLink"')                        'done renders Open deck link'
Assert ($dom -match 'href="file:///C:/Temp/status-demo/Week-1-deck\.html"') 'done link is a slashed file URL'
Assert (([regex]::Matches($dom, 'class="step done"')).Count -eq 5) 'done marks all five steps done'
Remove-Fixture $fx

# 2. running state: message rendered, build step active
$fx = New-StatusFixture $runningJs; $dom = Get-StatusDom $fx
Assert ($dom -match 'data-status-state="running"')                'running state marked on panel'
Assert ($dom -match 'Building template demo')                     'running message rendered'
Assert ($dom -match 'class="step active">Build template')         'running highlights the build step'
Remove-Fixture $fx

# 3. error state: failing step marked failed, message shown
$fx = New-StatusFixture $errorJs; $dom = Get-StatusDom $fx
Assert ($dom -match 'data-status-state="error"')                  'error state marked on panel'
Assert ($dom -match 'template repo missing')                      'error message rendered'
Assert ($dom -match 'class="step failed">Build template')         'error marks the failing step failed'
Assert ($dom -notmatch 'statusOpenLink')                          'error renders no open link'
Remove-Fixture $fx

# 4. waiting state: first step active, pickup message shown
$fx = New-StatusFixture $waitingJs; $dom = Get-StatusDom $fx
Assert ($dom -match 'picked up selection\.json')                  'waiting message rendered'
Assert ($dom -match 'class="step active">Read selection')         'waiting activates first step'
Remove-Fixture $fx

# 5. missing status.js: overlay stays hidden (idle)
$fx = New-StatusFixture $null; $dom = Get-StatusDom $fx
Assert ($dom -match 'data-status-state="idle"')                   'no status file leaves panel idle'
Assert ($dom -notmatch 'statusOpenLink')                          'no status file renders no open link'
Remove-Fixture $fx

# 6. stale status: older than the 1h rejoin window is ignored on load
$fx = New-StatusFixture $staleJs; $dom = Get-StatusDom $fx
Assert ($dom -notmatch 'statusOpenLink')                          'stale done status ignored on load'
Assert ($dom -match 'data-status-state="idle"')                   'stale status leaves panel idle'
Remove-Fixture $fx

if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0

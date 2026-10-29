param(
    [int]$TimeoutSec  = 3600,
    [int]$IntervalSec = 1,
    [switch]$NotifyOnly
)
$ErrorActionPreference = 'Stop'

$created = $false
$mtx = $null
try {
    $mtx = New-Object System.Threading.Mutex($true, 'Global\html-slides-picker-watcher', [ref]$created)
    if (-not $created) { exit 0 }   # a watcher is already on duty
} catch { }

function Get-State {
    if (-not (Test-Path $selectionPath)) { return '<none>' }
    $bytes = [IO.File]::ReadAllBytes($selectionPath)
    $sha = [System.Security.Cryptography.SHA256CryptoServiceProvider]::Create()
    try {
        return 'len=' + $bytes.Length +
            ';sha=' + ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-','')
    } finally { $sha.Dispose() }
}
$selectionPath = Join-Path $PSScriptRoot 'selection.json'
$baseline = Get-State
$started = Get-Date
Write-Host "watcher: waiting for selection.json change (cap ${TimeoutSec}s)..."

try {
    while ($true) {
        Start-Sleep -Seconds $IntervalSec
        if ((Get-State) -ne $baseline) {
            Write-Host 'watcher: selection.json changed.'
            if ($NotifyOnly) { exit 0 }
            $prompt  = "Build the html-slides deck described in $selectionPath. Never re-ask any question the JSON already answers."
            $inner   = 'opencode run "' + ($prompt -replace '"', '\"') + '"'
            if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
                Start-Process wt.exe -ArgumentList @('powershell.exe','-NoProfile','-NoExit','-Command', $inner)
            } else {
                Start-Process powershell.exe -ArgumentList @('-NoProfile','-NoExit','-Command', $inner)
            }
            exit 0
        }
        if (((Get-Date) - $started).TotalSeconds -gt $TimeoutSec) {
            Write-Host 'watcher: no change after cap; giving up softly.'
            exit 3
        }
    }
} finally {
    if ($created -and $mtx) { $mtx.ReleaseMutex(); $mtx.Dispose() }
}

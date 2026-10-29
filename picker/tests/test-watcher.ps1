$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Assert($cond, $name) {
    if ($cond) { Write-Host "PASS: $name"; $script:pass++ }
    else       { Write-Host "FAIL: $name"; $script:fail++ }
}
$picker  = Split-Path $PSScriptRoot          # picker\tests -> picker
$sel     = Join-Path $picker 'selection.json'
$watcher = Join-Path $picker 'watcher.ps1'
Assert (Test-Path $watcher) 'watcher.ps1 exists'

function Start-Watcher([string[]]$extra) {
    $all = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $watcher) + $extra
    Start-Process powershell -ArgumentList $all -PassThru -WindowStyle Hidden
}

# --- test 1: fresh trigger fires fast + file preserved
if (Test-Path $sel) { Remove-Item $sel -Force }
$p = Start-Watcher @('-NotifyOnly','-TimeoutSec','20')
Start-Sleep -Seconds 2
Set-Content -Path $sel -Value '{"template":"daisy-days"}' -Encoding UTF8
$sw = [Diagnostics.Stopwatch]::StartNew()
$p.WaitForExit(8000) | Out-Null
$sw.Stop()
Assert ($p.HasExited -and $p.ExitCode -eq 0 -and $sw.Elapsed.TotalSeconds -lt 8) "fresh trigger exits 0 within 8s (took $([math]::Round($sw.Elapsed.TotalSeconds,1))s)"
Assert (Test-Path $sel) 'selection.json preserved'

# --- test 2: same-mtime overwrite still triggers (hash-based)
Set-Content -Path $sel -Value '{"template":"monochrome"}' -Encoding UTF8
$origTime = (Get-Item $sel).LastWriteTimeUtc
$p = Start-Watcher @('-NotifyOnly','-TimeoutSec','20')
Start-Sleep -Seconds 2
Set-Content -Path $sel -Value '{"template":"broadside"}' -Encoding UTF8
(Get-Item $sel).LastWriteTimeUtc = $origTime      # force SHA-based detection
$sw = [Diagnostics.Stopwatch]::StartNew()
$p.WaitForExit(8000) | Out-Null
$sw.Stop()
Assert ($p.HasExited -and $p.ExitCode -eq 0 -and $sw.Elapsed.TotalSeconds -lt 8) 'same-mtime overwrite triggers'

# --- test 3: timeout -> exit 3, soft, sane duration
if (Test-Path $sel) { Remove-Item $sel -Force }
$p = Start-Watcher @('-NotifyOnly','-TimeoutSec','3')
$sw = [Diagnostics.Stopwatch]::StartNew()
$p.WaitForExit(10000) | Out-Null
$sw.Stop()
Assert ($p.ExitCode -eq 3) 'timeout exit code 3'
Assert ($sw.Elapsed.TotalSeconds -ge 2.5 -and $sw.Elapsed.TotalSeconds -lt 9) "timeout duration sane ($([math]::Round($sw.Elapsed.TotalSeconds,1))s)"

# --- cleanup
if (Test-Path $sel) { Remove-Item $sel -Force }
if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0

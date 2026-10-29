$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0
function Assert($cond, $name) {
    if ($cond) { Write-Host "PASS: $name"; $script:pass++ }
    else       { Write-Host "FAIL: $name"; $script:fail++ }
}
$root       = Split-Path (Split-Path $PSScriptRoot)
$picker     = Join-Path $root 'picker'
$browserTxt = Join-Path $picker 'web-browser.txt'
Assert (Test-Path $browserTxt) 'web-browser.txt exists'
if (Test-Path $browserTxt) {
    $browser = (Get-Content $browserTxt -Raw).Trim()
    Assert (Test-Path $browser) "browser exe exists ($browser)"
}
$ws = New-Object -ComObject WScript.Shell
foreach ($loc in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
    $lnkPath = Join-Path $loc 'HTML Slides Picker.lnk'
    Assert (Test-Path $lnkPath) "shortcut exists: $lnkPath"
    if (Test-Path $lnkPath) {
        $s = $ws.CreateShortcut($lnkPath)
        Assert ($s.TargetPath -eq (Join-Path $picker 'picker.cmd')) "shortcut targets picker.cmd: $lnkPath"
    }
}
$cmd = Get-Content (Join-Path $picker 'picker.cmd') -Raw
Assert ($cmd -match 'watcher\.ps1') 'picker.cmd starts watcher'
Assert ($cmd -match '--app=') 'picker.cmd opens app window'
if ($fail -gt 0) { Write-Host "$fail failed"; exit 1 }
Write-Host "all $pass checks passed"; exit 0

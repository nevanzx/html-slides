@echo off
setlocal enabledelayedexpansion
if not exist "%~dp0web-browser.txt" (
  echo No web-browser.txt - run picker\install.ps1 first.
  pause
  exit /b 1
)
for /f "usebackq delims=" %%i in ("%~dp0web-browser.txt") do set "BROWSER=%%i"
set "U=%~dp0picker.html"
set "U=!U:\=/!"
start "" "%BROWSER%" --app="file:///!U!"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0watcher.ps1" -TimeoutSec 3600
endlocal

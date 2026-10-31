@echo off
if exist "%~dp0dist\Patrician3ModernResolutions.exe" goto launch
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build.ps1"
if errorlevel 1 goto failed
:launch
start "" "%~dp0dist\Patrician3ModernResolutions.exe"
exit /b 0
:failed
pause
exit /b 1

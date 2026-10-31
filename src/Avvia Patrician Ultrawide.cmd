@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0mods-ultrawide\Avvia-Ultrawide.ps1"
if errorlevel 1 pause

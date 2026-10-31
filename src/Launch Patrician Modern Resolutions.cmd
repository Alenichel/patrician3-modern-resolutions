@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0mods-ultrawide\Apply-ResolutionPatch.ps1"
if errorlevel 1 pause

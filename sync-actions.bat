@echo off
rem this is a wrapper for PoserShell application

setlocal

set selected_project_arg=%1

Powershell.exe -ExecutionPolicy RemoteSigned -File "%~dp0\sync-actions.ps1" %selected_project_arg%

endlocal
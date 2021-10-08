@echo off
rem this is a wrapper for PoserShell application

setlocal

set selected_project_arg=%1
set no_interaction_arg=%2

Powershell.exe -ExecutionPolicy RemoteSigned -File "%~dp0\start-devbox.ps1" %selected_project_arg% %no_interaction_arg%

endlocal
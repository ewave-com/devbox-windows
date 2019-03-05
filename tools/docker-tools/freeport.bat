@echo off

set "tempfolder=%~dp0\tmp"

IF NOT EXIST %tempfolder% (
    md %tempfolder%
)

set service_name=%1
set start_port_default=1000

if "%startPort%" == "" (
    set startPort=%start_port_default%
)

set i=0
FOR /F "tokens=1* USEBACKQ" %%a IN (`Powershell.exe -ExecutionPolicy Bypass -File %~dp0\docker_used_ports.ps1`) DO (
    set dockerUsedPorts[%%a]=%%a
)

:SEARCHPORT

set /a startPort +=1
if defined dockerUsedPorts[%startPort%] (
    GOTO :SEARCHPORT
) ELSE (
    netstat -o -n -a | find "LISTENING" | find ":%startPort% " > NUL
    if "%ERRORLEVEL%" equ "0" (
        GOTO :SEARCHPORT
    ) ELSE (
        set freePort=%startPort%
        GOTO :FOUNDPORT
    )
)

:FOUNDPORT

set %service_name%=%freePort%

rem EXIT /B %freePort%
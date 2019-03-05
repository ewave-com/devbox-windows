@echo off
echo Don't close current window otherwise synchronisation will be stopped........

rem READING PARAMS

set web_container_name=%PROJECT_NAME%_%CONTAINER_WEB_NAME%


echo Web Container Name : "%web_container_name%"
echo Remote path in container: %UNISON_REMOTE_ROOT%

FOR /f "delims=" %%A IN ('docker port %web_container_name% 5000') DO SET "CMD_OUTPUT=%%A"
FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "UNISON_PORT=%%B"

@SET UNISON_LOCAL_ROOT="projects/%PROJECT_NAME%/%UNISON_LOCAL_ROOT%"
@SET UNISON_REMOTE_ROOT=socket://localhost:%UNISON_PORT%/%UNISON_REMOTE_ROOT%

echo Remote root: %UNISON_REMOTE_ROOT%

@SET IGNORE=

if exist .\configs\unison\%CONFIGS_PROVIDER_UNISON%\unison_ignore.bat (
    call .\configs\unison\%CONFIGS_PROVIDER_UNISON%\unison_ignore.bat
)

@set UNISONARGS=%UNISON_LOCAL_ROOT% %UNISON_REMOTE_ROOT% -prefer %UNISON_LOCAL_ROOT% -preferpartial "Path var -> %UNISON_REMOTE_ROOT%" -auto -batch %IGNORE%

rem *** Check for sync readiness ***
IF "%USE_UNISON_SYNC%" NEQ "1" (GOTO EXIT_SYNC)

@echo on

IF NOT EXIST  %LOCAL_ROOT%/vendor (
   rem **** Pulling files from container (faster quiet mode) ****
   .\tools\windows\unison %UNISONARGS%
)

rem **** Entering file watch mode ****
:loop_sync
    .\tools\windows\unison %UNISONARGS% -repeat watch -fastcheck yes
    timeout 5
    @GOTO loop_sync
PAUSE

:EXIT_SYNC
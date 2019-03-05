@echo OFF
SET start_dir=%~dp0
cd ../..
call tools\windows\unset-env.bat

set COMPOSE_CONVERT_WINDOWS_PATHS=1

Powershell.exe -ExecutionPolicy Bypass -File tools\docker-tools\select-project.ps1 PROJECT_SELECTED tools\docker-tools\tmp\project.txt
call tools\docker-tools\env-reader.bat PROJECT_SELECTED tools\docker-tools\tmp\project.txt
IF "%PROJECT_SELECTED%" EQU "" (

  echo "Project is not detected. Try Again".
  GOTO END
)
set PROJECT_NAME=%PROJECT_SELECTED%

call tools\windows\set-env.bat

set web_container_name_full=%PROJECT_NAME%_%CONTAINER_WEB_NAME%
set mysql_container_name_full=%PROJECT_NAME%_%CONTAINER_MYSQL_NAME%

echo ================================================
echo [START] Unison for %PROJECT_NAME%
echo ================================================
rem UNISON sync
start call tools\windows\unison.bat

:ENDSCRIPT
GOTO END

:ENDERROR
echo ==================================================================
echo Unison UP has been stopped because of error(s). Fix it and try again.
echo ==================================================================

:END
cd /D %start_dir%
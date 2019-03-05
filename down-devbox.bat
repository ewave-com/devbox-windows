@echo off

setlocal

call tools\windows\unset-env.bat

Powershell.exe -ExecutionPolicy Bypass -File %~dp0\tools\docker-tools\select-project.ps1 PROJECT_SELECTED tools\docker-tools\tmp\project.txt
call tools\docker-tools\env-reader.bat PROJECT_SELECTED tools\docker-tools\tmp\project.txt

set PROJECT_NAME=%PROJECT_SELECTED%
call tools\windows\set-env.bat
set mysql_container_name_full=%PROJECT_NAME%_%CONTAINER_MYSQL_NAME%

Powershell.exe -executionpolicy remotesigned -File tools\docker-tools\kill-containers.ps1 %PROJECT_NAME% %mysql_container_name_full%

call tools\windows\unset-env.bat

endlocal
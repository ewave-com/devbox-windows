@echo off
setlocal enabledelayedexpansion enableextensions

echo Moving docker configs to project level folder ...

if exist %~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up (
    del %~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\*.* /F /Q
)

IF EXIST %~dp0\..\..\..\projects\%PROJECT_NAME%\ports.txt (
    SET PortsFile=%~dp0\..\..\..\projects\%PROJECT_NAME%\ports.txt
) ELSE (
    SET PortsFile=%~dp0\..\..\..\configs\ports.txt
)

SET "UseContainers="
SET "ProcessedContainers="
SET "ContainerTypeToName="

FOR /F "tokens=1,6 delims=|" %%a IN (%PortsFile%) DO (
    set "TempUse="
    IF "%%b" == "" (
        set TempUse=1
    ) ELSE (
        IF DEFINED %%b (
            FOR /F "tokens=2 delims==" %%m IN ('set %%b') DO (
                IF "%%m" == "yes" (
                    set tempUse=1
                )
            )
        )
    )
    IF DEFINED TempUse (
        set UseContainers[%%a]=%%a
        FOR /F "tokens=2 delims==" %%m IN ('set %%a') DO (
            IF NOT DEFINED ProcessedContainers[%%m] (
                IF NOT DEFINED ContainerTypeToName (
                    set ContainerTypeToName=%%a:%PROJECT_NAME%_%%m
                ) ELSE (
                    set ContainerTypeToName=!ContainerTypeToName!,%%a:%PROJECT_NAME%_%%m
                )
                set ProcessedContainers[%%m]=%%m
            )
        )
    )
)
FOR /f "tokens=1* USEBACKQ delims==" %%a IN (`Powershell.exe -ExecutionPolicy Bypass -File %~dp0\..\project_dynamic_ports.ps1 %ContainerTypeToName% -PortsFile %PortsFile%`) DO (
    set %%a=%%b
)
FOR /F "tokens=1,4,5 delims=|" %%a IN (%PortsFile%) DO (
    IF DEFINED UseContainers[%%a] (
        IF NOT DEFINED %%b (
            call %~dp0\..\freeport.bat %%b
        )
        FOR /F "tokens=2 delims==" %%m IN ('set %%b') DO (
            echo %%c - %%m
        )
    )
)

set "redissource=%~dp0\..\..\..\configs\docker\docker-compose-redis.yml"
set "redisdest=%~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\docker-compose-redis.yml"
set "maindestpath=%~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\docker-compose-website-main.yml"
set "elsource=%~dp0\..\..\..\configs\docker\docker-compose-elastic.yml"
set "eldest=%~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\docker-compose-elastic.yml"

IF "%VARNISH_ENABLE%" == "yes" (
     set "mainsourcepath=%~dp0\..\..\..\configs\docker\docker-compose-website-varnish.yml"
     echo Varnish enable : yes
     GOTO WEB_CONTAINER_END
)

IF "%BLACKFIRE_ENABLE%" == "yes" (
     set "mainsourcepath=%~dp0\..\..\..\configs\docker\docker-compose-website-blackfire.yml"
     echo Black Fire enable : yes
     GOTO WEB_CONTAINER_END
)

set "mainsourcepath=%~dp0\..\..\..\configs\docker\docker-compose-website.yml"

:WEB_CONTAINER_END

echo %mainsourcepath%
echo %maindestpath%

Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %mainsourcepath% %maindestpath%

echo Nginx + PHP + MySql : yes
FOR /F "tokens=1,2,3,4 delims=|" %%a IN (%PortsFile%) DO (
    IF DEFINED UseContainers[%%a] (
        FOR /F "tokens=2 delims==" %%m IN ('set %%d') DO (
            Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %maindestpath% %maindestpath% {{%%d}} %%m
            Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %maindestpath% %maindestpath% {{%%c}} %%b
        )
    )
)
IF "%REDIS_ENABLE%" == "yes" (
     Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %redissource% %redisdest%
     echo Redis enable : yes
)

IF "%ELASTIC_ENABLE%" == "yes" (
     Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %elsource% %eldest%
     echo Elastic enable : yes
)

echo Moving .env files to "docker-up" level folder ...
set "envsource=%~dp0\..\..\..\projects\%PROJECT_NAME%\.env"
set "envdest=%~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\.env"
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %envsource% %envdest%

if exist %~dp0\..\..\..\projects\%PROJECT_NAME%\.env-files-mapping.json (
    set "envfsource=%~dp0\..\..\..\projects\%PROJECT_NAME%\.env-files-mapping.json"
    set "envfdest=%~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\.env-files-mapping.json"
    Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %envfsource% %envfdest%
)

if not exist "%~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\configs" mkdir %~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\configs
del %~dp0\..\..\..\projects\%PROJECT_NAME%\docker-up\configs\*.* /F /Q
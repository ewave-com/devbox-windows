@echo off

setlocal

call tools\windows\unset-env.bat
call tools\windows\unset-additional-env.bat

type tools\docker-tools\sys\start.txt

rem Convert windoes path - required for docker-compose
set COMPOSE_CONVERT_WINDOWS_PATHS=1
rem The port value for dynamic ports calculation
set startPort=1000
set log_level=ERROR

rem prepare required folders and files
call tools\docker-tools\replacer\clear-temp-storage.bat

Powershell.exe -ExecutionPolicy Bypass -File %~dp0\tools\docker-tools\select-project.ps1 PROJECT_SELECTED tools\docker-tools\tmp\project.txt
call tools\docker-tools\env-reader.bat PROJECT_SELECTED tools\docker-tools\tmp\project.txt

echo ================================================
echo [START PROJECT] : %PROJECT_SELECTED%
echo ================================================
IF "%PROJECT_SELECTED%" EQU "" (
  echo "Project to run is not detected. Try Again".
  GOTO END
)

rem READING PARAMS
set PROJECT_NAME=%PROJECT_SELECTED%

call tools\windows\set-env.bat

set up_mode=up -d
rem IF "%DOWN_FLAG%" == "stop" (set up_mode="start") ELSE (set up_mode=up -d)

set web_container_name_full=%PROJECT_NAME%_%CONTAINER_WEB_NAME%
set mysql_container_name_full=%PROJECT_NAME%_%CONTAINER_MYSQL_NAME%

FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -aqf "name=%web_container_name_full%"`) DO (
    SET web_container_id_old=%%F
)
FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -aqf "name=%mysql_container_name_full%"`) DO (
    SET mysql_container_id_old=%%F
)

echo "Container Up Mode: %up_mode%"

echo ================================================
echo Checking / Adding domain records to the system host file....
call tools\docker-tools\replacer\host-file-replacer.bat %PROJECT_NAME%

rem Move required docker configs to project level -> docker-up folder
call tools\docker-tools\replacer\configs-mover.bat
Powershell.exe -executionpolicy remotesigned -File %~dp0\tools\docker-tools\replacer\configs-mover-custom.ps1 %PROJECT_NAME%

rem Replace xdebug, nginx etc. configs patterns usgin env variables
call tools\docker-tools\replacer\configs-replacer.bat
Powershell.exe -executionpolicy remotesigned -File %~dp0\tools\docker-tools\replacer\configs-replacer-custom.ps1 %PROJECT_NAME%

echo ================================================
echo [UP]: Portainer
echo ================================================
rem up MailHog + Portainer
docker-compose --log-level %log_level% -f configs\docker\docker-compose-portainer.yml %up_mode%

echo ================================================
echo [UP]: Mailer
echo ================================================
docker-compose --log-level %log_level% -f configs\docker\docker-compose-%MAILER_TYPE%.yml %up_mode%

echo ================================================
echo [UP]: [PROJECT LEVEL CONTAINERS]
echo ================================================

Powershell.exe -executionpolicy remotesigned -File %~dp0\tools\docker-tools\up-containers.ps1 %PROJECT_NAME% "%up_mode%"

FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -aqf "name=%mysql_container_name_full%"`) DO (
    SET mysql_container_id_new=%%F
)

IF [%mysql_container_id_old%] NEQ [%mysql_container_id_new%] (
    IF "%DOWN_FLAG%" NEQ  "stop" (
        echo ================================================
        echo [DB EXTRACT]: ./sysdumps/mysql to mysql:/var/lib/mysql
        echo ================================================
        ping -n 5 127.0.0.1 | find "Reply" > nul
        echo copying db files to mysql container. Container may down after copying...
        docker exec -i %mysql_container_name_full% sh -c "mkdir -p /var/lib/mysql"
        docker cp projects/%PROJECT_NAME%/sysdumps/mysql %mysql_container_name_full%:/var/lib
    )
)

rem Create ssl certificate
IF "%WEBSITE_PROTOCOL%" == "https" (
docker exec -it %web_container_name_full% /bin/bash -c "openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) -keyout /etc/nginx/ssl/%WEBSITE_HOST_NAME%.key -out /etc/nginx/ssl/%WEBSITE_HOST_NAME%.crt -days 365 -subj "/C=BY/ST=Minsk/L=Minsk/O=DevOpsTeam_EWave/CN=%WEBSITE_HOST_NAME%""
)

echo ================================================
echo [UP]: Nginx Reverse Proxy
echo ================================================
docker-compose --log-level %log_level% -f configs\docker\docker-compose-nginx-proxy.yml %up_mode%

echo ================================================
echo [RESTART]: Mysql container again after DB extracting
echo ================================================
docker start %mysql_container_name_full%

echo ================================================
echo [CREATE] Platform tools alias "platform-tools"
docker exec -it %web_container_name_full% /bin/bash -c "echo 'alias platform-tools='\'/usr/bin/php %TOOLS_PROVIDER_REMOTE_PATH%/%TOOLS_PROVIDER_ENTRYPOINT%\''' >> ~/.bashrc"
docker exec -it %web_container_name_full% /bin/bash -c "echo 'alias platform-tools='\'/usr/bin/php %TOOLS_PROVIDER_REMOTE_PATH%/%TOOLS_PROVIDER_ENTRYPOINT%\''' >> /var/www/.bashrc && chown -R www-data:www-data /var/www/.bashrc"

echo ================================================
echo Move git folder up to project level
echo y|del %~dp0projects\%PROJECT_NAME%\.git\*
Powershell.exe -ExecutionPolicy Bypass -File %~dp0tools\docker-tools\move-items.ps1 %~dp0projects\%PROJECT_NAME%\public_html\.git\* %~dp0projects\%PROJECT_NAME%\.git\

FOR /F "tokens=* USEBACKQ" %%F IN (`docker ps -aqf "name=%web_container_name_full%"`) DO (
    SET web_container_id_new=%%F
)

IF [%web_container_id_old%] NEQ [%web_container_id_new%] (
    echo ================================================
    echo [WEB FILES EXTRACTING...]
    echo ================================================
    echo "docker cp projects/%PROJECT_NAME%/public_html/. %web_container_name_full%:%UNISON_REMOTE_ROOT%/"
    docker cp projects/%PROJECT_NAME%/public_html/. %web_container_name_full%:%UNISON_REMOTE_ROOT%
)

echo ================================================
echo Move git folder back to project level
Powershell.exe -ExecutionPolicy Bypass -File %~dp0\tools\docker-tools\move-items.ps1 %~dp0\projects\%PROJECT_NAME%\.git\* %~dp0\projects\%PROJECT_NAME%\public_html\.git\

echo ================================================
echo [RESTART]: Nginx revers-proxy
echo ================================================
docker restart  nginx-reverse-proxy

echo ================================================
echo [START] Unison
echo ================================================
rem UNISON sync
start call tools\windows\unison.bat

echo ================================================
echo [START] The Platform deploy tool has been started [source : existing project]
echo ================================================
echo "The command : /usr/bin/php %TOOLS_PROVIDER_REMOTE_PATH%/%TOOLS_PROVIDER_ENTRYPOINT%"
docker exec -it %web_container_name_full% /bin/bash -c "/usr/bin/php %TOOLS_PROVIDER_REMOTE_PATH%/%TOOLS_PROVIDER_ENTRYPOINT% --autostart"
GOTO ENDSCRIPT
:SKIP1

:ENDSCRIPT
echo ================================================
echo [LINKS]
echo ================================================
call tools\docker-tools\sys\information.bat
@echo off
type tools\docker-tools\sys\finished.txt
call tools\windows\unset-env.bat
call tools\windows\unset-additional-env.bat
pause
GOTO END

:ENDERROR
echo ==================================================================
echo DevBox UP has been stopped because of error(s). Fix it and try again.
echo ==================================================================

:END

endlocal
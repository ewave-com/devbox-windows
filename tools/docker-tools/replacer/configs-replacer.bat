@echo off

echo Replacing Parameters in config files ...

echo IP Address : "%MACHINE_IP_ADDRESS%"

IF "%WEBSITE_PROTOCOL%" == "https" (
set "nginxproxysource=configs\nginx-reversproxy\%CONFIGS_PROVIDER_NGINX_PROXY%\conf.d\https.conf.pattern"
set "nginxproxyout=configs\nginx-reversproxy\run\website-https-proxy-%PROJECT_NAME%.conf"
)

IF "%WEBSITE_PROTOCOL%" == "http" (
set "nginxproxysource=configs\nginx-reversproxy\%CONFIGS_PROVIDER_NGINX_PROXY%\conf.d\http.conf.pattern"
set "nginxproxyout=configs\nginx-reversproxy\run\website-http-proxy-%PROJECT_NAME%.conf"
)

set "varnishsource=configs\varnish\%CONFIGS_PROVIDER_VARNISH%\default.vcl.pattern"
set "varnishdest=projects\%PROJECT_NAME%\docker-up\configs\varnish\%CONFIGS_PROVIDER_VARNISH%\default.vcl"

echo "Website Host Name : %WEBSITE_HOST_NAME%"
echo "Document Root : %WEBSITE_DOCUMENT_ROOT%"

rem PHP
echo Replacing PHP and XDebug config...
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 configs\php\%CONFIGS_PROVIDER_PHP%\ini\xdebug.ini.pattern projects\%PROJECT_NAME%\docker-up\configs\php\%CONFIGS_PROVIDER_PHP%\ini\xdebug.ini {{your-local-ip}} "host.docker.internal"
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 configs\php\%CONFIGS_PROVIDER_PHP%\ini\zzz-custom.ini projects\%PROJECT_NAME%\docker-up\configs\php\%CONFIGS_PROVIDER_PHP%\ini\zzz-custom.ini
rem ===============================================================

rem NGINX
echo Replacing Nginx configs...
set "nginxsource=configs\nginx\%CONFIGS_PROVIDER_NGINX%\conf\website.conf.pattern"
set "nginxout=projects\%PROJECT_NAME%\docker-up\configs\nginx\%CONFIGS_PROVIDER_NGINX%\conf\website-%PROJECT_NAME%.conf"
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxsource% %nginxout% {{host-name}} %WEBSITE_HOST_NAME%
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxout% %nginxout% {{document_root}} %WEBSITE_DOCUMENT_ROOT%
rem ===============================================================

rem MySql
echo Replacing Mysql configs...
set "mysqlsource=configs\mysql\%CONFIGS_PROVIDER_MYSQL%\db\conf.d\custom.cnf"
set "mysqldest=projects\%PROJECT_NAME%\docker-up\configs\mysql\%CONFIGS_PROVIDER_MYSQL%\db\conf.d\custom.cnf"
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %mysqlsource% %mysqldest%
rem ===============================================================

rem Varnish

IF "%VARNISH_ENABLE%" == "yes" (

    echo Replacing Varnish configs...
    Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %varnishsource% %varnishdest% {{project_name}} %PROJECT_NAME%
    Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %varnishdest% %varnishdest% {{web_container_name}} %CONTAINER_WEB_NAME%
)
rem ===============================================================

rem NGINX-REVERS-PROXY

if exist configs\nginx-reversproxy\run\website-http-proxy-%PROJECT_NAME%.conf (
    del configs\nginx-reversproxy\run\website-http-proxy-%PROJECT_NAME%.conf
)
if exist configs\nginx-reversproxy\run\website-https-proxy-%PROJECT_NAME%.conf (
    del configs\nginx-reversproxy\run\website-https-proxy-%PROJECT_NAME%.conf
)

echo Replacing Nginx-Revers-Proxy config...

Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxproxysource% %nginxproxyout% {{host-name}} %WEBSITE_HOST_NAME%
if "%VARNISH_ENABLE%" == "yes" (
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxproxyout% %nginxproxyout% {{web_container_name}} varnish
)
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxproxyout% %nginxproxyout% {{web_container_name}} %CONTAINER_WEB_NAME%
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxproxyout% %nginxproxyout% {{project_name}} %PROJECT_NAME%

if "%VARNISH_ENABLE%" == "yes" (
    echo Varnish is used as layer. Nginx-Proxy [%CONTAINER_VARNISH_NAME%: %VARNISH_PORT_DYNAMIC%]
    rem VARNISH GOES FIRST [NGINX PROXY -> VARNISH -> WEBSITE]
    Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxproxyout% %nginxproxyout% {{web_container_name}} %CONTAINER_VARNISH_NAME%
) ELSE (
    rem VARNISH GOES FIRST [NGINX PROXY -> WEBSITE]
    Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxproxyout% %nginxproxyout% {{web_container_name}} %CONTAINER_WEB_NAME%
)
Powershell.exe -executionpolicy remotesigned -File %~dp0text-replacer.ps1 %nginxproxyout% %nginxproxyout% {{project_web_container_port}} "80"
rem ===============================================================


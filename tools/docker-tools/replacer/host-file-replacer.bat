@echo off

set PROJECT_NAME=%1
call %~dp0\..\env-reader.bat WEBSITE_HOST_NAME %~dp0\..\..\..\projects\%PROJECT_NAME%\.env

>nul find "%WEBSITE_HOST_NAME%" %WINDIR%\System32\drivers\etc\hosts && (
  goto host_exist
)

::::::::::::::::::::::::::::::::::::::::::::
:: Automatically check & get admin rights V2
::::::::::::::::::::::::::::::::::::::::::::
@echo off
CLS
ECHO.
ECHO =============================
ECHO Running Admin shell
ECHO =============================

:init
setlocal DisableDelayedExpansion
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion

:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
ECHO.
ECHO **************************************
ECHO Invoking UAC for Privilege Escalation
ECHO **************************************

ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
ECHO args = "ELEV " >> "%vbsGetPrivileges%"
ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
ECHO Next >> "%vbsGetPrivileges%"
ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*

rem exit /B

:gotPrivileges
setlocal & pushd .
cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

::::::::::::::::::::::::::::
::START
::::::::::::::::::::::::::::

set PROJECT_NAME=%1

echo Getting IP address and Host Name from Config File.
echo ====================================

call %~dp0\..\env-reader.bat MACHINE_IP_ADDRESS ..\..\..\projects\%PROJECT_NAME%\.env
call %~dp0\..\env-reader.bat WEBSITE_HOST_NAME ..\..\..\projects\%PROJECT_NAME%\.env
echo %WEBSITE_HOST_NAME%
echo %MACHINE_IP_ADDRESS%

setlocal enabledelayedexpansion
rem =========================================================

::Create your list of host domains
set LIST=(%WEBSITE_HOST_NAME%)
::Set the ip of the domains you set in the list above
set %WEBSITE_HOST_NAME%=%MACHINE_IP_ADDRESS%
:: deletes the parentheses from LIST
set _list=%LIST:~1,-1%
::ECHO %WINDIR%\System32\drivers\etc\hosts > tmp.txt
for  %%G in (%_list%) do (
    set  _name=%%G
    set  _value=!%%G!
    SET NEWLINE=^& echo.
    ECHO Carrying out requested modifications to your HOSTS file
    ::strip out this specific line and store in tmp file
    type %WINDIR%\System32\drivers\etc\hosts | findstr /v !_name! > tmp.txt
    ::re-add the line to it
    ECHO %NEWLINE%^!_value! !_name!>>tmp.txt
    ::overwrite host file
    copy /b/v/y tmp.txt %WINDIR%\System32\drivers\etc\hosts
    del tmp.txt
)

rem =========================================================
endlocal

ipconfig /flushdns
:host_exist
@ECHO OFF
echo stopping containers...
FOR /f "tokens=*" %%i IN ('docker ps -aq') DO docker stop %%i
echo killing containers...
FOR /f "tokens=*" %%i IN ('docker ps -aq') DO docker rm %%i
echo clearing nginx configs
RMDIR /S /Q %~dp0\..\..\configs\nginx-reversproxy\run
@echo off

echo[
echo [ PROJECT ]
echo[


echo    Project Name :  %PROJECT_NAME%
echo    Frontend URL : http://%WEBSITE_HOST_NAME%/
echo    Website Nginx Port : %WEB_CONTAINER_PORT_DYNAMIC%
echo    Website remote document root : %WEBSITE_DOCUMENT_ROOT%
echo    Web Container Connection : docker exec -it %PROJECT_NAME%_%CONTAINER_WEB_NAME% /bin/bash

echo[
echo [ MYSQL ]
echo[

echo    Database Name : %CONTAINER_MYSQL_DB_NAME%
echo    [INSIDE]  DB Connection: mysql -uroot -p%CONTAINER_MYSQL_ROOT_PASS% -h %PROJECT_NAME%_%CONTAINER_MYSQL_NAME%
echo    [OUTSIDE] DB Connection: mysql -uroot -p%CONTAINER_MYSQL_ROOT_PASS% -h localhost -P %MYSQL_PORT_DYNAMIC%

echo[
echo [ PORTAINER ]
echo[
echo    Portainer URL: http://%MACHINE_IP_ADDRESS%:%PORTAINER_PORT%/

echo[
echo [ MAILHOG ]
echo[

echo    MailHog URL: http://%MACHINE_IP_ADDRESS%:%MAILHOG_PORT%/

echo[
echo [ REDIS ]
echo[

echo    Redis Host : %PROJECT_NAME%_redis
echo    Redis Connection : redis-cli -h %PROJECT_NAME%_%CONTAINER_REDIS_NAME%

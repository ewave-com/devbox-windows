call tools\docker-tools\env-reader.bat PLATFORM_NAME
call tools\docker-tools\env-reader.bat PROJECT_NAME
rem call tools\docker-tools\env-reader.bat COMPOSE_PROJECT_NAME
call tools\docker-tools\env-reader.bat MACHINE_IP_ADDRESS
call tools\docker-tools\env-reader.bat COMPOSE_CONVERT_WINDOWS_PATHS
call tools\docker-tools\env-reader.bat PORTAINER_PORT
call tools\docker-tools\env-reader.bat MAILHOG_PORT
call tools\docker-tools\env-reader.bat REDIS_ENABLE
call tools\docker-tools\env-reader.bat CONTAINER_REDIS_NAME
call tools\docker-tools\env-reader.bat BLACKFIRE_ENABLE
call tools\docker-tools\env-reader.bat BLACKFIRE_SERVER_ID_T
call tools\docker-tools\env-reader.bat BLACKFIRE_SERVER_TOKEN_T
call tools\docker-tools\env-reader.bat BLACKFIRE_CLIENT_ID_T
call tools\docker-tools\env-reader.bat BLACKFIRE_CLIENT_TOKEN_T
call tools\docker-tools\env-reader.bat VARNISH_ENABLE
call tools\docker-tools\env-reader.bat CONTAINER_VARNISH_NAME
call tools\docker-tools\env-reader.bat CONFIGS_PROVIDER_VARNISH
call tools\docker-tools\env-reader.bat ELASTIC_ENABLE
call tools\docker-tools\env-reader.bat CONTAINER_ELASTIC_NAME
call tools\docker-tools\env-reader.bat CONFIGS_PROVIDER_ELASTIC
call tools\docker-tools\env-reader.bat CONFIGS_PROVIDER_NGINX_PROXY
call tools\docker-tools\env-reader.bat CONTAINER_WEB_NAME
call tools\docker-tools\env-reader.bat CONTAINER_WEB_IMAGE
call tools\docker-tools\env-reader.bat WEBSITE_HOST_NAME
call tools\docker-tools\env-reader.bat WEBSITE_PROTOCOL
call tools\docker-tools\env-reader.bat WEBSITE_DOCUMENT_ROOT
call tools\docker-tools\env-reader.bat CONFIGS_PROVIDER_NGINX
call tools\docker-tools\env-reader.bat CONFIGS_PROVIDER_PHP
call tools\docker-tools\env-reader.bat CONTAINER_MYSQL_NAME
call tools\docker-tools\env-reader.bat CONTAINER_MYSQL_VERSION
call tools\docker-tools\env-reader.bat CONTAINER_MYSQL_PORT
call tools\docker-tools\env-reader.bat CONTAINER_MYSQL_DB_NAME
call tools\docker-tools\env-reader.bat CONTAINER_MYSQL_ROOT_PASS
call tools\docker-tools\env-reader.bat CONFIGS_PROVIDER_MYSQL
call tools\docker-tools\env-reader.bat USE_UNISON_SYNC
call tools\docker-tools\env-reader.bat UNISON_LOCAL_ROOT
call tools\docker-tools\env-reader.bat UNISON_REMOTE_ROOT
call tools\docker-tools\env-reader.bat CONFIGS_PROVIDER_UNISON
rem call tools\docker-tools\env-reader.bat TOOLS_PROVIDER
call tools\docker-tools\env-reader.bat TOOLS_PROVIDER_REMOTE_PATH
call tools\docker-tools\env-reader.bat TOOLS_PROVIDER_ENTRYPOINT
call tools\docker-tools\env-reader.bat PROJECT_CONFIGURATION_FILE
call tools\docker-tools\env-reader.bat MAILER_TYPE
rem All parameters below are deprecated, will be moved to the '.env-project.json' file soon
call tools\docker-tools\env-reader.bat CODE_SOURCE_PATH
call tools\docker-tools\env-reader.bat CODE_SOURCE_BRANCH
call tools\docker-tools\env-reader.bat CODE_SOURCE_TEMP_PATH
call tools\docker-tools\env-reader.bat MEDIA_GIT_PATH
call tools\docker-tools\env-reader.bat MEDIA_TEMP_STORAGE_PATH
call tools\docker-tools\env-reader.bat DATABASE_SOURCE_PATH
call tools\docker-tools\env-reader.bat DATABASE_TEMP_STORAGE
call tools\docker-tools\env-reader.bat DATABASE_SOURCE_TYPE
call tools\docker-tools\env-reader.bat DATABASE_SOURCE_LOGIN
call tools\docker-tools\env-reader.bat DATABASE_SOURCE_PASSWORD
call tools\docker-tools\env-reader.bat CONFIGS_SOURCE_PATH
call tools\docker-tools\env-reader.bat CONFIGS_SOURCE_TYPE
call tools\docker-tools\env-reader.bat CONFIGS_SOURCE_LOGIN
call tools\docker-tools\env-reader.bat CONFIGS_SOURCE_PASSWORD
call tools\docker-tools\env-reader.bat CONFIGS_SOURCE_PATH_TEMP_STORAGE

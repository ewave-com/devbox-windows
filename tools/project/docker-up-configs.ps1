. require_once "${devbox_root}/tools/system/file.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/project/project-dotenv.ps1"
. require_once "${devbox_root}/tools/project/project-state.ps1"

############################ Public functions ############################

function prepare_project_docker_up_configs() {
    New-Item -ItemType Directory -Path "${project_up_dir}" -Force | Out-Null

    prepare_website_configs

    if (${MYSQL_ENABLE} -eq "yes") {
        prepare_mysql_configs
    }

    if (${VARNISH_ENABLE} -eq "yes") {
        prepare_varnish_configs
    }

    if (${ELASTICSEARCH_ENABLE} -eq "yes") {
        prepare_elasticsearch_configs
    }

    if (${REDIS_ENABLE} -eq "yes") {
        prepare_redis_configs
    }

    if (${BLACKFIRE_ENABLE} -eq "yes") {
        prepare_blackfire_configs
    }

    if (${POSTGRES_ENABLE} -eq "yes") {
        prepare_postgres_configs
    }

    if (${MONGODB_ENABLE} -eq "yes") {
        prepare_mongodb_configs
    }

    if (${RABBITMQ_ENABLE} -eq "yes") {
        prepare_rabbitmq_configs
    }

    if (${CUSTOM_COMPOSE}) {
        prepare_custom_configs
    }
}

function cleanup_project_docker_up_configs() {
    Remove-Item -Path "${project_up_dir}/docker-compose-*.yml" -Force -ErrorAction Ignore

    Remove-Item -Path "${project_up_dir}/docker-sync-*.yml" -Force -ErrorAction Ignore

    Remove-Item -Path "${project_up_dir}/configs" -Force -Recurse -ErrorAction Ignore

    Remove-Item -Path "${project_up_dir}/docker-sync/" -Force -Recurse -ErrorAction Ignore

    Remove-Item -Path "${project_up_dir}/nginx-reverse-proxy/" -Force -Recurse -ErrorAction Ignore

    Remove-Item -Path "${project_up_dir}/project-stopped.flag" -Force -ErrorAction Ignore

    remove_state_file
}

############################ Public functions end ############################

############################ Local functions ############################

function prepare_website_configs() {
    copy_path_with_project_fallback "configs/docker-compose/docker-compose-website.yml" "${project_up_dir}/docker-compose-website.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-website.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_WEBSITE_DOCKER_SYNC}) {
        copy_path_with_project_fallback "configs/docker-sync/website/${CONFIGS_PROVIDER_WEBSITE_DOCKER_SYNC}/docker-sync-website.yml" "${project_up_dir}/docker-sync-website.yml"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-sync-website.yml" "${project_up_dir}/.env"
    }

    # prepare composer cache sync or remove volume references if not required
    if (${CONFIGS_PROVIDER_COMPOSER_CACHE_DOCKER_SYNC}) {
        copy_path_with_project_fallback "configs/docker-sync/composer/${CONFIGS_PROVIDER_COMPOSER_CACHE_DOCKER_SYNC}/docker-sync-composer.yml" "${project_up_dir}/docker-sync-composer.yml"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-sync-composer.yml" "${project_up_dir}/.env"
    } else {
        # remove sync mentioning from website volumes list
        $_sync_name="${PROJECT_NAME}_${CONTAINER_WEB_NAME}_composer_cache_sync"
        $_content = Get-Content -Path "${project_up_dir}/docker-compose-website.yml"  | Select-String -Pattern "${_sync_name}:/var/www/.composer" -NotMatch
        $_content | Set-Content -Path "${project_up_dir}/docker-compose-website.yml"

        # remove extenal volume section
        $_content = Get-Content -Path "${project_up_dir}/docker-compose-website.yml"
        $_pattern_line_index = ($_content | Select-String -Pattern "${_sync_name}:$" | Select LineNumber)
        (($_content | select -first ($_pattern_line_index.LineNumber - 1) ), ($_content | select -skip ($_pattern_line_index.LineNumber + 1))) | Set-Content -Path "${project_up_dir}/docker-compose-website.yml"
    }

    # prepare node_modules sync or remove volume references if not required
    if (${CONFIGS_PROVIDER_NODE_MODULES_DOCKER_SYNC}) {
        copy_path_with_project_fallback "configs/docker-sync/node_modules/${CONFIGS_PROVIDER_NODE_MODULES_DOCKER_SYNC}/docker-sync-node_modules.yml" "${project_up_dir}/docker-sync-node_modules.yml"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-sync-node_modules.yml" "${project_up_dir}/.env"
    } else {
        # remove sync mentioning from website volumes list
        $_sync_name="${PROJECT_NAME}_${CONTAINER_WEB_NAME}_node_modules_sync"
        $_content = Get-Content -Path "${project_up_dir}/docker-compose-website.yml" | Select-String -Pattern "${_sync_name}:/var/www/node_modules_remote" -NotMatch
        $_content | Set-Content -Path "${project_up_dir}/docker-compose-website.yml"

        # remove extenal volume section
        $_content = Get-Content -Path "${project_up_dir}/docker-compose-website.yml"
        $_pattern_line_index = ($_content | Select-String -Pattern "${_sync_name}:$" | Select LineNumber)
        (($_content | select -first ($_pattern_line_index.LineNumber - 1) ), ($_content | select -skip ($_pattern_line_index.LineNumber + 1))) | Set-Content -Path "${project_up_dir}/docker-compose-website.yml"
    }

    prepare_website_nginx_configs
    prepare_website_php_configs
    prepare_website_bash_configs

    New-Item -ItemType Directory -Path "${project_up_dir}/configs/cron/" -Force | Out-Null
}

# This function use in add_domain function
function prepare_website_nginx_configs() {
    New-Item -ItemType Directory -Path "${project_up_dir}/configs/cron/" -Force | Out-Null
    New-Item -ItemType Directory -Path "${project_up_dir}/configs/nginx/logs/" -Force | Out-Null

    $_config_target_filepath = "${project_up_dir}/configs/nginx/conf.d/${WEBSITE_HOST_NAME}.conf"

    copy_path_with_project_fallback "configs/nginx/${CONFIGS_PROVIDER_NGINX}/conf/website.conf.pattern" "${_config_target_filepath}"

    $_website_nginx_extra_host_names = ''
    if (${WEBSITE_EXTRA_HOST_NAMES}) {
        $_website_nginx_extra_host_names = ("${WEBSITE_EXTRA_HOST_NAMES}" -Replace ',', ' ')
    }

    replace_value_in_file "${_config_target_filepath}" "{{website_extra_host_names_nginx_list}}" "${_website_nginx_extra_host_names}"

    # todo deprecated section, will be removed later, now vars are passed using function replace_file_patterns_with_dotenv_params
    replace_value_in_file "${_config_target_filepath}" "{{host_name}}" "${WEBSITE_HOST_NAME}"
    replace_value_in_file "${_config_target_filepath}" "{{document_root}}" "${WEBSITE_APPLICATION_ROOT}"
    # todo deprecated section end

    replace_file_patterns_with_dotenv_params "${_config_target_filepath}" "${project_up_dir}/.env"
}

function prepare_website_php_configs() {
    New-Item -ItemType Directory -Path "${project_up_dir}/configs/php/" -Force | Out-Null

    if (${CONFIGS_PROVIDER_PHP}) {
        # processed files by default: php/ini/xdebug.ini.pattern, php/ini/zzz-custom.ini.pattern
        copy_path_with_project_fallback "configs/php/${CONFIGS_PROVIDER_PHP}/" "${project_up_dir}/configs/php/"

        # todo deprecated section, will be removed later, now vars are passed using function replace_file_patterns_with_dotenv_params
        if (Test-Path "${project_up_dir}/configs/php/ini/xdebug.ini.pattern" -PathType Leaf) {
            replace_value_in_file "${project_up_dir}/configs/php/ini/xdebug.ini.pattern" "{{server_ip}}" "${WEBSITE_PHP_XDEBUG_HOST}"
        }
        if (Test-Path "${project_up_dir}/configs/php/ini/xdebug.ini" -PathType Leaf) {
            replace_value_in_file "${project_up_dir}/configs/php/ini/xdebug.ini" "{{server_ip}}" "${WEBSITE_PHP_XDEBUG_HOST}"
        }
        # todo deprecated section end

        if (Test-Path "${project_up_dir}/configs/php/auto_prepend_file.php" -PathType Leaf) {
            $_prepend_path = "/etc/php/${PHP_VERSION}/auto_prepend_file.php"
        } else {
            $_prepend_path=""
        }
        if (Test-Path "${project_up_dir}/configs/php/ini/zzz-custom.ini.pattern" -PathType Leaf) {
            replace_value_in_file "${project_up_dir}/configs/php/ini/zzz-custom.ini.pattern" "{{auto_prepend_filepath}}" "${_prepend_path}"
        }

        replace_directory_files_patterns_with_dotenv_params "${project_up_dir}/configs/php/" "${project_up_dir}/.env"
    }
}

function prepare_website_bash_configs() {
    New-Item -ItemType Directory -Path "${project_up_dir}/configs/bash/" -Force | Out-Null

    if (-not (Test-Path "${project_up_dir}/bash_history_web" -PathType Leaf)) {
        New-Item -Path "${project_up_dir}/bash_history_web" | Out-Null
    }

    if (${CONFIGS_PROVIDER_BASH}) {
        copy_path_with_project_fallback "configs/bash/${CONFIGS_PROVIDER_BASH}/bashrc_www-data" "${project_up_dir}/configs/bash/bashrc_www-data"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/configs/bash/bashrc_www-data" "${project_up_dir}/.env"

        replace_file_line_endings "${project_up_dir}/configs/bash/bashrc_www-data"

        copy_path_with_project_fallback "configs/bash/${CONFIGS_PROVIDER_BASH}/bashrc_root" "${project_up_dir}/configs/bash/bashrc_root"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/configs/bash/bashrc_root" "${project_up_dir}/.env"

        replace_file_line_endings "${project_up_dir}/configs/bash/bashrc_root"
    }
}

function prepare_mysql_configs() {
    New-Item -ItemType Directory -Path "${project_up_dir}/configs/mysql/conf.d/" -Force | Out-Null

    copy_path_with_project_fallback "configs/docker-compose/docker-compose-mysql.yml" "${project_up_dir}/docker-compose-mysql.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-mysql.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_MYSQL_DOCKER_SYNC}) {
        copy_path_with_project_fallback "configs/docker-sync/mysql/${CONFIGS_PROVIDER_MYSQL_DOCKER_SYNC}/docker-sync-mysql.yml" "${project_up_dir}/docker-sync-mysql.yml"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-sync-mysql.yml" "${project_up_dir}/.env"
    }

    if (${CONFIGS_PROVIDER_MYSQL}) {
        copy_path_with_project_fallback "configs/mysql/${CONFIGS_PROVIDER_MYSQL}/conf.d/custom.cnf" "${project_up_dir}/configs/mysql/conf.d/custom.cnf"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/configs/mysql/conf.d/custom.cnf" "${project_up_dir}/.env"
    }
}

function prepare_varnish_configs() {
    New-Item -ItemType Directory -Path "${project_up_dir}/configs/varnish/" -Force | Out-Null

    copy_path_with_project_fallback "configs/docker-compose/docker-compose-varnish.yml" "${project_up_dir}/docker-compose-varnish.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-varnish.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_VARNISH}) {
        copy_path_with_project_fallback "configs/varnish/${CONFIGS_PROVIDER_VARNISH}/default.vcl.pattern" "${project_up_dir}/configs/varnish/default.vcl"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/configs/varnish/default.vcl" "${project_up_dir}/.env"
    }
}

function prepare_elasticsearch_configs() {
    copy_path_with_project_fallback "configs/docker-compose/docker-compose-elasticsearch.yml" "${project_up_dir}/docker-compose-elasticsearch.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-elasticsearch.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_ELASTICSEARCH_DOCKER_SYNC}) {
        copy_path_with_project_fallback "configs/docker-sync/elasticsearch/${CONFIGS_PROVIDER_ELASTICSEARCH_DOCKER_SYNC}/docker-sync-elasticsearch.yml" "${project_up_dir}/docker-sync-elasticsearch.yml"
        replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-sync-elasticsearch.yml" "${project_up_dir}/.env"
    }

    if (${CONFIGS_PROVIDER_ELASTICSEARCH}) {
        copy_path_with_project_fallback "configs/elasticsearch/${CONFIGS_PROVIDER_ELASTICSEARCH}/" "${project_up_dir}/configs/elasticsearch/"
        replace_directory_files_patterns_with_dotenv_params "${project_up_dir}/configs/elasticsearch/" "${project_up_dir}/.env"
    }
}

function prepare_redis_configs() {
    copy_path_with_project_fallback "configs/docker-compose/docker-compose-redis.yml" "${project_up_dir}/docker-compose-redis.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-redis.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_REDIS}) {
        copy_path_with_project_fallback "configs/redis/${CONFIGS_PROVIDER_REDIS}/" "${project_up_dir}/configs/redis/"
        replace_directory_files_patterns_with_dotenv_params "${project_up_dir}/configs/redis/" "${project_up_dir}/.env"
    }
}

function prepare_blackfire_configs() {
    copy_path_with_project_fallback "configs/docker-compose/docker-compose-blackfire.yml" "${project_up_dir}/docker-compose-blackfire.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-blackfire.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_BLACKFIRE}) {
        copy_path_with_project_fallback "configs/blackfire/${CONFIGS_PROVIDER_BLACKFIRE}/" "${project_up_dir}/configs/blackfire/"
        replace_directory_files_patterns_with_dotenv_params "${project_up_dir}/configs/blackfire/" "${project_up_dir}/.env"
    }
}

function prepare_postgres_configs() {
    copy_path_with_project_fallback "configs/docker-compose/docker-compose-postgres.yml" "${project_up_dir}/docker-compose-postgres.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-postgres.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_POSTGRES}) {
        copy_path_with_project_fallback "configs/postgres/${CONFIGS_PROVIDER_POSTGRES}/" "${project_up_dir}/configs/postgres/"
        replace_directory_files_patterns_with_dotenv_params "${project_up_dir}/configs/postgres/" "${project_up_dir}/.env"
    }
}

function prepare_mongodb_configs() {
    copy_path_with_project_fallback "configs/docker-compose/docker-compose-mongodb.yml" "${project_up_dir}/docker-compose-mongodb.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-mongodb.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_MONGODB}) {
        copy_path_with_project_fallback "configs/mongodb/${CONFIGS_PROVIDER_MONGODB}/" "${project_up_dir}/configs/mongodb/"
        replace_directory_files_patterns_with_dotenv_params "${project_up_dir}/configs/mongodb/" "${project_up_dir}/.env"
    }
}

function prepare_rabbitmq_configs() {
    copy_path_with_project_fallback "configs/docker-compose/docker-compose-rabbitmq.yml" "${project_up_dir}/docker-compose-rabbitmq.yml"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/docker-compose-rabbitmq.yml" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_RABBITMQ}) {
        copy_path_with_project_fallback "configs/rabbitmq/${CONFIGS_PROVIDER_RABBITMQ}/" "${project_up_dir}/configs/rabbitmq/"
        replace_directory_files_patterns_with_dotenv_params "${project_up_dir}/configs/rabbitmq/" "${project_up_dir}/.env"
    }
}

function prepare_custom_configs() {
    copy_path_with_project_fallback "configs/docker/${CUSTOM_COMPOSE}" "${project_up_dir}/${CUSTOM_COMPOSE}"
    replace_file_patterns_with_dotenv_params "${project_up_dir}/${CUSTOM_COMPOSE}" "${project_up_dir}/.env"

    if (${CONFIGS_PROVIDER_CUSTOM}) {
        copy_path_with_project_fallback "configs/custom/${CONFIGS_PROVIDER_CUSTOM}/*" "${project_up_dir}/configs/custom/"
        replace_directory_files_patterns_with_dotenv_params "${project_up_dir}/configs/custom/" "${project_up_dir}/.env"
    }
}

############################ Local functions end ############################

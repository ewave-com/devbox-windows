. require_once "${devbox_root}/tools/docker/docker.ps1"
. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/system/file.ps1"
. require_once "${devbox_root}/tools/system/dotenv.ps1"
. require_once "${devbox_root}/tools/system/free-port.ps1"
. require_once "${devbox_root}/tools/system/wsl.ps1"
. require_once "${devbox_root}/tools/project/docker-up-configs.ps1"

############################ Public functions ############################

# prepare generated project .env file in docker-up dir and export all variables
function prepare_project_dotenv_variables($_force = $false) {
    prepare_project_dotenv_file ${_force}
    dotenv_export_variables "${project_up_dir}/.env"
}

############################ Public functions end ############################

############################ Local functions ############################

# copy project .env file into docker-up dir and prepare it before work
function prepare_project_dotenv_file($_force = $false) {
    # last docker run was crashed, files may be created as directories, clean all before starting
    if (Test-Path "${project_up_dir}/.env" -PathType Container) {
        cleanup_project_docker_up_configs
        Remove-Item "$project_up_dir/.env" -Force -Recurse
    }

    if (-not (Test-Path "${project_dir}/.env" -PathType Leaf)) {
        show_error_message "File .ENV not found! Please put configuration file exists at path '${project_dir}/.env' and try again."
        exit 1
    }

    if ((Test-Path "${project_up_dir}/.env" -PathType Leaf) -and (-not $_force)) {
        return
    }

    New-Item -ItemType Directory -Path "${project_up_dir}" -Force | Out-Null

    Copy-Item "${project_dir}/.env" -Destination "${project_up_dir}/.env" -Force
    Add-Content -Path "${project_dir}/.env" -Value ""

    replace_file_line_endings "${project_up_dir}/.env"

    $current_env_filepath = "${project_up_dir}/.env"

    apply_backward_compatibility_transformations "${project_up_dir}/.env"
    merge_defaults "${project_up_dir}/.env"
    add_computed_params "${project_up_dir}/.env"
    evaluate_expression_values "${project_up_dir}/.env"
    add_internal_generated_prams "${project_up_dir}/.env"

    $current_env_filepath = ""
}

# apply backward compatibility transformations
function apply_backward_compatibility_transformations($_env_filepath = "${project_up_dir}/.env") {
    # copy value of deprecated WEBSITE_DOCUMENT_ROOT into new params if empty
    if ((dotenv_has_param 'WEBSITE_DOCUMENT_ROOT') -and -not (dotenv_get_param_value 'WEBSITE_SOURCES_ROOT')) {
        dotenv_set_param_value 'WEBSITE_SOURCES_ROOT' "$( dotenv_get_param_value 'WEBSITE_DOCUMENT_ROOT' )"
    }
    if ((dotenv_has_param 'WEBSITE_DOCUMENT_ROOT') -and -not (dotenv_get_param_value 'WEBSITE_APPLICATION_ROOT')) {
        dotenv_set_param_value 'WEBSITE_APPLICATION_ROOT' "$( dotenv_get_param_value 'WEBSITE_DOCUMENT_ROOT' )"
    }

    # append php version to image name for madebyewave image
    $_web_image = (dotenv_get_param_value 'CONTAINER_WEB_IMAGE')
    $_php_version = (dotenv_get_param_value 'PHP_VERSION')
    if ("${_web_image}" -eq 'madebyewave/devbox-nginx-php') {
        dotenv_set_param_value 'CONTAINER_WEB_IMAGE' "${_web_image}${_php_version}"
    }

    # config params *ELASTIC* were renamed to *ELASTICSEARCH*, copy all params with new names
    if (dotenv_has_param 'ELASTIC_ENABLE' -and -not (dotenv_get_param_value 'ELASTICSEARCH_ENABLE')) {
        dotenv_set_param_value 'ELASTICSEARCH_ENABLE' "$( dotenv_get_param_value 'ELASTIC_ENABLE' )"
    }
    if (dotenv_has_param 'CONTAINER_ELASTIC_NAME' -and -not (dotenv_get_param_value 'CONTAINER_ELASTICSEARCH_NAME')) {
        dotenv_set_param_value 'CONTAINER_ELASTICSEARCH_NAME' "$( dotenv_get_param_value 'CONTAINER_ELASTIC_NAME' )"
    }
    if (dotenv_has_param 'CONTAINER_ELASTIC_IMAGE' -and -not (dotenv_get_param_value 'CONTAINER_ELASTICSEARCH_IMAGE')) {
        dotenv_set_param_value 'CONTAINER_ELASTICSEARCH_IMAGE' "$( dotenv_get_param_value 'CONTAINER_ELASTIC_IMAGE' )"
    }
    if (dotenv_has_param 'CONTAINER_ELASTIC_VERSION' -and -not (dotenv_get_param_value 'CONTAINER_ELASTICSEARCH_VERSION')) {
        dotenv_set_param_value 'CONTAINER_ELASTICSEARCH_VERSION' "$( dotenv_get_param_value 'CONTAINER_ELASTIC_VERSION' )"
    }
    if (dotenv_has_param 'CONFIGS_PROVIDER_ELASTIC' -and -not (dotenv_get_param_value 'CONFIGS_PROVIDER_ELASTICSEARCH')) {
        dotenv_set_param_value 'CONFIGS_PROVIDER_ELASTICSEARCH' "$( dotenv_get_param_value 'CONFIGS_PROVIDER_ELASTIC' )"
    }

    if ((dotenv_has_param 'CONFIGS_PROVIDER_UNISON') -and ! (dotenv_get_param_value 'CONFIGS_PROVIDER_WEBSITE_DOCKER_SYNC')) {
        dotenv_set_param_value 'CONFIGS_PROVIDER_WEBSITE_DOCKER_SYNC' "$( dotenv_get_param_value 'CONFIGS_PROVIDER_UNISON' )"
    }

    # force disable previous unison config as it is replaced with docker-sync
    dotenv_set_param_value 'USE_UNISON_SYNC' "0"
}

# merge existed .env file with project-defaults.env to collect all required parameters
function merge_defaults($_env_filepath = "${project_up_dir}/.env") {
    if (-not (Test-Path ${_env_filepath} -PathType Leaf)) {
        show_error_message "Unable to apply .env defaults. Project .env file doesn't exist at path '${_env_filepath}'."
        exit 1
    }

    Add-Content -Path ${_env_filepath} -Value ""
    Add-Content -Path ${_env_filepath} -Value ""
    Add-Content -Path ${_env_filepath} -Value "########## Generated params ##########"
    Add-Content -Path ${_env_filepath} -Value "# The following params are evaluated or imported from defaults file: '${dotenv_defaults_filepath}'"

    foreach ($_param_line in (Get-Content -Path ${dotenv_defaults_filepath} | Select-String -Pattern '(^$)|(^#)' -NotMatch | Select -ExpandProperty Line)) {
        $_param_name = $_param_line.Split('=')[0]
        if (-not (dotenv_has_param "${_param_name}" ${_env_filepath})) {
            $_param_default_value = ($_param_line.Split('=')[1])
            Add-Content -Path ${_env_filepath} -Value "${_param_name}=${_param_default_value}"
        }
    }
}

# check if dynamic ports are available to be exposed, used on simplified start with existing .env
function ensure_exposed_container_ports_are_available($_env_filepath = "${project_up_dir}/.env") {
    $current_env_filepath = "${_env_filepath}"

    $_project_name = (dotenv_get_param_value 'PROJECT_NAME')

    # ensure mysql external port is available to be exposed or compute a free one
    $_mysql_enable = (dotenv_get_param_value 'MYSQL_ENABLE')
    if ("${_mysql_enable}" -eq "yes") {
        $_configured_mysql_port = $( dotenv_get_param_value 'CONTAINER_MYSQL_PORT' )
        if ($_configured_mysql_port) {
            $_mysql_container_name = "${_project_name}_$(dotenv_get_param_value 'CONTAINER_MYSQL_NAME')"
            ensure_mysql_port_is_available ${_configured_mysql_port} ${_mysql_container_name}
        }
    }

    # ensure elasticsearch external port is available to be exposed or compute a free one
    $_es_enable = $( dotenv_get_param_value 'ELASTICSEARCH_ENABLE' )
    if ("${_es_enable}" -eq "yes") {
        $_configured_es_port = (dotenv_get_param_value 'CONTAINER_ELASTICSEARCH_PORT')
        if ($_configured_es_port) {
            $_es_container_name = "${_project_name}_$(dotenv_get_param_value 'CONTAINER_ELASTICSEARCH_NAME')"
            ensure_elasticsearch_port_is_available ${_configured_es_port} ${_es_container_name}
        }
    }

    $_configured_ssh_port = (dotenv_get_param_value 'CONTAINER_WEB_SSH_PORT')
    if ($_configured_ssh_port) {
        $_web_container_name = "${_project_name}_$(dotenv_get_param_value 'CONTAINER_WEB_NAME')"
        ensure_website_ssh_port_is_available ${_configured_ssh_port} ${_web_container_name}
    }

    $current_env_filepath = ""
}

# add comupted params like dynamic ports or hosts
function add_computed_params($_env_filepath = "${project_up_dir}/.env") {
    $_project_name = (dotenv_get_param_value 'PROJECT_NAME')

    # ensure mysql external port is available to be exposed or compute a free one
    $_mysql_enable = (dotenv_get_param_value 'MYSQL_ENABLE')
    if ("${_mysql_enable}" -eq "yes") {
        $_mysql_container_name = "${_project_name}_$(dotenv_get_param_value 'CONTAINER_MYSQL_NAME')"
        $_configured_mysql_port = $( dotenv_get_param_value 'CONTAINER_MYSQL_PORT' )
        if ($_configured_mysql_port) {
            ensure_mysql_port_is_available ${_configured_mysql_port} ${_mysql_container_name}
        } else {
            $_mysql_container_state = (get_docker_container_state "${_mysql_container_name}")
            if ($_mysql_container_state) {
                $_computed_mysql_port = (get_mysql_port_from_existing_container "${_mysql_container_name}")
                if (-not ($_mysql_container_state -eq "running")) {
                    ensure_mysql_port_is_available ${_computed_mysql_port} ${_mysql_container_name}
                }
            } else {
                $_computed_mysql_port = (get_available_mysql_port)
            }

            dotenv_set_param_value 'CONTAINER_MYSQL_PORT' ${_computed_mysql_port}
        }
    }

    # ensure elasticsearch external port is available to be exposed or compute a free one
    $_es_enable = $( dotenv_get_param_value 'ELASTICSEARCH_ENABLE' )
    if ("${_es_enable}" -eq "yes") {
        $_es_container_name="${_project_name}_$(dotenv_get_param_value 'CONTAINER_ELASTICSEARCH_NAME')"
        $_configured_es_port = (dotenv_get_param_value 'CONTAINER_ELASTICSEARCH_PORT')
        if ($_configured_es_port) {
            ensure_elasticsearch_port_is_available ${_configured_es_port} ${_es_container_name}
        } else {
            $_es_container_state = (get_docker_container_state "${_es_container_name}")
            if ($_es_container_state) {
                $_computed_es_port = (get_elasticsearch_port_from_existing_container "${_es_container_name}")
                if (-not ($_es_container_state -eq "running")) {
                    ensure_elasticsearch_port_is_available ${_computed_es_port} ${_es_container_name}
                }
            } else {
                $_computed_es_port = (get_available_elasticsearch_port)
            }

            dotenv_set_param_value 'CONTAINER_ELASTICSEARCH_PORT' ${_computed_es_port}
        }
    }

    $_web_container_name = "${_project_name}_$(dotenv_get_param_value 'CONTAINER_WEB_NAME')"
    $_configured_ssh_port = (dotenv_get_param_value 'CONTAINER_WEB_SSH_PORT')
    if ($_configured_ssh_port) {
        ensure_website_ssh_port_is_available ${_configured_ssh_port} ${_web_container_name}
    } else {
        $_web_container_state = (get_docker_container_state "${_web_container_name}")
        if ($_web_container_state) {
            $_computed_ssh_port = (get_website_ssh_port_from_existing_container "${_web_container_name}")
            if (-not ($_web_container_state -eq "running")) {
                ensure_website_ssh_port_is_available ${_computed_ssh_port} ${_web_container_name}
            }
        } else {
            $_computed_ssh_port = (get_available_website_ssh_port)
        }

        dotenv_set_param_value 'CONTAINER_WEB_SSH_PORT' ${_computed_ssh_port}
    }

    # fill WEBSITE_PHP_XDEBUG_HOST if empty
    $_configured_xdebug_host = (dotenv_get_param_value 'WEBSITE_PHP_XDEBUG_HOST')
    if (-not ${_configured_xdebug_host}) {
        $_computed_xdebug_host = "host.docker.internal"
        dotenv_set_param_value 'WEBSITE_PHP_XDEBUG_HOST' "${_computed_xdebug_host}"
    }

    # set OS mysql docker-sync type if 'default' chosen
    $_mysql_docker_sync_provider = (dotenv_get_param_value 'CONFIGS_PROVIDER_MYSQL_DOCKER_SYNC')
    if (${_mysql_docker_sync_provider} -eq "default") {
        $_mysql_docker_sync_provider = "native"
        dotenv_set_param_value 'CONFIGS_PROVIDER_MYSQL_DOCKER_SYNC' "${_mysql_docker_sync_provider}"
    }
    #forced unison for wsl, until hybrid mode is implemented
    if ($preferred_sync_env -eq "wsl") {
        dotenv_set_param_value 'CONFIGS_PROVIDER_MYSQL_DOCKER_SYNC' "unison"
    }

    # set OS elasticsearch docker-sync type if 'default' chosen
    $_es_docker_sync_provider = (dotenv_get_param_value 'CONFIGS_PROVIDER_ELASTICSEARCH_DOCKER_SYNC')
    if (${_es_docker_sync_provider} -eq "default") {
        $_es_docker_sync_provider = "native"
        dotenv_set_param_value 'CONFIGS_PROVIDER_ELASTICSEARCH_DOCKER_SYNC' "${_es_docker_sync_provider}"
    }
    #forced unison for wsl, until hybrid mode is implemented
    if ($preferred_sync_env -eq "wsl") {
        dotenv_set_param_value 'CONFIGS_PROVIDER_ELASTICSEARCH_DOCKER_SYNC' "unison"
    }
}

# add static dir paths required for docker-sync mounting
function add_internal_generated_prams($_env_filepath = "${project_up_dir}/.env") {
    if (-not (dotenv_get_param_value 'DEVBOX_PROJECT_DIR')) {
        $_resolved_project_dir = (Resolve-Path ${project_dir})
        if ($preferred_sync_env -eq "wsl") {
            $_resolved_project_dir = (get_wsl_path (Resolve-Path ${project_dir}))
        }

        dotenv_set_param_value 'DEVBOX_PROJECT_DIR' $_resolved_project_dir
    }

    if (-not (dotenv_get_param_value 'DEVBOX_PROJECT_UP_DIR')) {
        $_resolved_project_up_dir = (Resolve-Path ${project_up_dir})
        if ($preferred_sync_env -eq "wsl") {
            $_resolved_project_up_dir = (get_wsl_path ($_resolved_project_up_dir))
        }

        dotenv_set_param_value 'DEVBOX_PROJECT_UP_DIR' $_resolved_project_up_dir
    }

    if (-not (dotenv_get_param_value 'COMPOSER_CACHE_DIR')) {
        $_composer_cache_dir = ''
        if ((dotenv_get_param_value 'CONFIGS_PROVIDER_COMPOSER_CACHE_DOCKER_SYNC') -eq 'global') {
            $_composer_cache_dir = (composer config --global cache-dir)
            New-Item -ItemType Directory -Path "${_composer_cache_dir}" -Force | Out-Null
        } elseif((dotenv_get_param_value 'CONFIGS_PROVIDER_COMPOSER_CACHE_DOCKER_SYNC') -eq 'local') {
            $_composer_cache_dir = "${project_dir}/sysdumps/composer"
            New-Item -ItemType Directory -Path "${_composer_cache_dir}" -Force | Out-Null
        }

        if ($preferred_sync_env -eq "wsl" -and $_composer_cache_dir) {
            $_composer_cache_dir = (get_wsl_path $_composer_cache_dir)
        }
        dotenv_set_param_value 'COMPOSER_CACHE_DIR' $_composer_cache_dir
    }

    # evaluate relative app path inside sources root to configure sync properly
    if(-not (dotenv_get_param_value 'WEBSITE_SOURCES_ROOT')) {
        if ( (dotenv_get_param_value 'WEBSITE_SOURCES_ROOT') -ne (dotenv_get_param_value 'WEBSITE_APPLICATION_ROOT') ) {
            $_sources_root = (dotenv_get_param_value 'WEBSITE_SOURCES_ROOT')
            $_app_root = (dotenv_get_param_value 'WEBSITE_APPLICATION_ROOT')
            $_app_relative_path = (((${_app_root} -Replace "${_sources_root}", '') -Replace "^/", '') -Replace "/$", '')

            if (${_app_relative_path}) {
                dotenv_set_param_value 'APP_REL_PATH' "${_app_relative_path}/"
            }
        }
    }

    # evaluate relative node_modules path inside sources root to configure sync properly
    if(-not (dotenv_get_param_value 'NODE_MODULES_REL_PATH')) {
        if ((dotenv_get_param_value 'WEBSITE_NODE_MODULES_ROOT')) {
            $_sources_root = (dotenv_get_param_value 'WEBSITE_SOURCES_ROOT')
            $_node_modules_root = (dotenv_get_param_value 'WEBSITE_NODE_MODULES_ROOT')
            $_node_modules_relative_path = (((${_node_modules_root} -Replace "${_sources_root}", '') -Replace "^/", '') -Replace "/$", '')

            if (${_node_modules_relative_path}) {
                dotenv_set_param_value 'NODE_MODULES_REL_PATH' "${_node_modules_relative_path}/"
            }
        }
    }

    if(-not (dotenv_get_param_value 'DOCKER_SYNC_UNISON_IMAGE')) {
        if ($arch_type -eq 'arm64') {
            dotenv_set_param_value 'DOCKER_SYNC_UNISON_IMAGE' "eugenmayer/unison:2.51.3-4.12.0-ARM64"
        } else {
            dotenv_set_param_value 'DOCKER_SYNC_UNISON_IMAGE' "eugenmayer/unison:2.51.3-4.12.0-AMD64"
        }
    }
}

# evaluate .env param value expressions, for example 'PARAM_1=${PARAM_2}_$PARAM_3' will be evaluated based on PARAM_2 and PARAM_3 from same file
function evaluate_expression_values($_env_filepath = "${project_up_dir}/.env") {
    foreach ($_param_line in (Get-Content -Path ${_env_filepath} | Select-String -Pattern '(^$)|(^#)' -NotMatch | Select-String -Pattern '\$' | Select -ExpandProperty Line)) {
        $_param_value = $_param_line.Split('=')[1]
        $_evaluated_param_value = ${_param_value}

        # if value has patterns like "${_some_word_}" or "$_some_word_" it should be evaluated
        if ($_param_value | Select-String '\$\{?[A-Za-z0-9_-]*\}?') {
            foreach ($_param_pattern in ($_param_value | Select-String '(\$\{?[A-Za-z0-9_-]*\}?)' -AllMatches | ForEach-Object -MemberName Matches | ForEach-Object { $_.Groups[1].Value })) {
                $_eval_param_name = ($_param_pattern -Replace '\$|{|}', '')
                $_evaluated_value = (dotenv_get_param_value "${_eval_param_name}")
                $_param_pattern = [regex]::Escape(${_param_pattern}) # escape regex chars, otherwise Replace is not working because of special characters
                $_evaluated_param_value = ($_evaluated_param_value -Replace "${_param_pattern}", "${_evaluated_value}")
            }
        }

        if ("${_evaluated_param_value}" -ne "${_param_value}") {
            $_param_name = $_param_line.Split('=')[0]
            dotenv_set_param_value "${_param_name}" "${_evaluated_param_value}"
        }
    }
}

############################ Local functions end ############################

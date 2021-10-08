. require_once "${devbox_root}/tools/docker/docker-compose.ps1"
. require_once "${devbox_root}/tools/docker/docker.ps1"
. require_once "${devbox_root}/tools/docker/network.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/system/dotenv.ps1"
. require_once "${devbox_root}/tools/system/free-port.ps1"

############################ Public functions ############################

# Start infrastructure docker services, e.g. nginx, portainer, mailhog, etc.
function start_infrastructure($_dotenv_filepath = "${dotenv_infra_filepath}") {
    replace_file_line_endings "${_dotenv_filepath}"

    create_docker_network

    if (-not (is_docker_container_running 'portainer')) {
        ensure_port_is_available (dotenv_get_param_value 'PORTAINER_PORT' "${_dotenv_filepath}")
        docker_compose_up "${devbox_infra_dir}/docker-compose-portainer.yml" "${_dotenv_filepath}"
    }

    if (-not (is_docker_container_running 'nginx-reverse-proxy')) {
        ensure_port_is_available "80"
        ensure_port_is_available "443"
        docker_compose_up "${devbox_infra_dir}/docker-compose-nginx-reverse-proxy.yml" "${_dotenv_filepath}"
    }

    $_mailer_type = $( dotenv_get_param_value 'MAILER_TYPE' "${_dotenv_filepath}" )
    if (${_mailer_type} -eq "mailhog" -or ${_mailer_type} -eq "exim4") {
        if (-not (is_docker_container_running 'mailer')) {
            if (${_mailer_type} -eq "mailhog") {
                ensure_port_is_available (dotenv_get_param_value 'MAILHOG_PORT' "${_dotenv_filepath}")
                docker_compose_up "${devbox_infra_dir}/docker-compose-mailhog.yml" "${_dotenv_filepath}"
                return
            }

            if (${_mailer_type} -eq "exim4") {
                docker_compose_up "${devbox_infra_dir}/docker-compose-exim4.yml" "${_dotenv_filepath}"
                return
            }
        }
    }

    if ((dotenv_get_param_value 'ADMINER_ENABLE' "${_dotenv_filepath}") -eq "yes") {
        if (-not (is_docker_container_running 'adminer')) {
            ensure_port_is_available (dotenv_get_param_value 'ADMINER_PORT' "${_dotenv_filepath}")
            docker_compose_up "${devbox_infra_dir}/docker-compose-adminer.yml" "${_dotenv_filepath}"
        }
    }
}

# Stop infrastructure docker services
function stop_infrastructure($_dotenv_filepath = "${dotenv_infra_filepath}") {
    replace_file_line_endings "${_dotenv_filepath}"

    if (is_docker_container_running 'mailer') {
        $_mailer_type = (dotenv_get_param_value 'MAILER_TYPE' "${_dotenv_filepath}")
        if (${_mailer_type} -eq "mailhog") {
            docker_compose_down "${devbox_infra_dir}/docker-compose-mailhog.yml" "${_dotenv_filepath}"
        } elseif (${_mailer_type} -eq "exim4") {
            docker_compose_down "${devbox_infra_dir}/docker-compose-exim4.yml" "${_dotenv_filepath}"
        }
    }

    if (is_docker_container_running 'adminer') {
        docker_compose_down "${devbox_infra_dir}/docker-compose-adminer.yml" "${_dotenv_filepath}"
    }

    # Delete orphaned files, all other should be deleted during project stopping
    Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/conf.d/*" -Force | Out-Null
    Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/logs/*" -Force | Out-Null
    if (is_docker_container_running 'nginx-reverse-proxy') {
        docker_compose_down "${devbox_infra_dir}/docker-compose-nginx-reverse-proxy.yml" "${_dotenv_filepath}"
    }

    if (is_docker_container_running 'portainer') {
        docker_compose_down "${devbox_infra_dir}/docker-compose-portainer.yml" "${_dotenv_filepath}"
    }
}

# Down infrastructure docker services
function down_infrastructure($_dotenv_filepath = "${dotenv_infra_filepath}") {
    replace_file_line_endings "${_dotenv_filepath}"

    # sometimes infrastructure containers may hang after downing, kill and rm them to avoid this, also this helps to clear all orphaned data
    # nginx-reverse proxy has additional kill signal and called as background task because of this

    # down mailer
    if (is_docker_container_running 'mailer') {
        $_mailer_type = (dotenv_get_param_value 'MAILER_TYPE' "${_dotenv_filepath}")
        if (${_mailer_type} -eq "mailhog") {
            docker_compose_down "${devbox_infra_dir}/docker-compose-mailhog.yml" "${_dotenv_filepath}"
        } elseif (${_mailer_type} -eq "exim4") {
            docker_compose_down "${devbox_infra_dir}/docker-compose-exim4.yml" "${_dotenv_filepath}"
        }
    }
    if (is_docker_container_running 'mailer') { kill_container_by_name "mailer" }
    if (is_docker_container_exist 'mailer') { rm_container_by_name "mailer" }

    # down adminer
    if (is_docker_container_running 'adminer') {
        docker_compose_down "${devbox_infra_dir}/docker-compose-adminer.yml" "${_dotenv_filepath}"
    }
    if (is_docker_container_running 'adminer') { kill_container_by_name "adminer" }
    if (is_docker_container_exist 'adminer') { rm_container_by_name "adminer" }

    # down nginx-reverse-proxy
    Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/conf.d/*" -Force | Out-Null
    Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/logs/*" -Force | Out-Null
    if (is_docker_container_running 'nginx-reverse-proxy') {
        docker_compose_down "${devbox_infra_dir}/docker-compose-nginx-reverse-proxy.yml" "${_dotenv_filepath}"
    }
    if (is_docker_container_running 'nginx-reverse-proxy') { kill_container_by_name "nginx-reverse-proxy" "SIGTERM" }
    if (is_docker_container_exist 'nginx-reverse-proxy') { rm_container_by_name "nginx-reverse-proxy" }

    # down portainer
    if (is_docker_container_running 'portainer') {
        docker_compose_down "${devbox_infra_dir}/docker-compose-portainer.yml" "${_dotenv_filepath}"
    }
    if (is_docker_container_running 'portainer') { kill_container_by_name "portainer" }
    if (is_docker_container_exist 'portainer') { rm_container_by_name "portainer" }

    remove_docker_network
}

############################ Public functions end ############################

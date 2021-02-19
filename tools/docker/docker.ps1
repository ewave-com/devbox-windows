. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"

############################ Public functions ############################

function is_docker_container_running($_container_name = "") {
    if (-not $_container_name) {
        show_error_message "Unable to check active docker containers. Container name cannot be empty."
        exit 1
    }

    $_result = Invoke-Expression "docker ps -a --filter='name=${_container_name}' --filter=status=running --format='{{.Names}}'"
    if ($_result) {
        return $true
    } else {
        return $false
    }
}

function is_docker_container_exist($_container_name = "") {
    if (-not $_container_name) {
        show_error_message "Unable to check existing docker container. Container name cannot be empty."
        exit 1
    }

    $_result = Invoke-Expression "docker ps -a --filter='name=${_container_name}' --format='{{.Names}}'"
    if ($_result) {
        return $true
    } else {
        return $false
    }
}

function stop_container_by_name($_container_name = "") {
    if (-not $_container_name) {
        show_error_message "Unable to stop docker container. Container name cannot be empty."
        exit 1
    }

    Invoke-Expression "docker stop (docker ps -q --filter='name=${_container_name}') --time 10" | Out-null
}

function kill_container_by_name($_container_name = "", $_signal = "SIGKILL") {
    if (-not $_container_name) {
        show_error_message "Unable to kill docker container. Container name cannot be empty."
        exit 1
    }

    Invoke-Expression "docker kill (docker ps -aq --filter='name=${_container_name}') -s ${_signal}" | Out-null
}

function rm_container_by_name($_container_name = "", $_force = $false) {
    if (-not $_container_name) {
        show_error_message "Unable to remove docker container. Container name cannot be empty."
        exit 1
    }

    if ($_force) {
        Invoke-Expression "docker rm ( docker ps -aq --filter=name=${_container_name} ) --force" | Out-null
    } else {
        Invoke-Expression "docker rm ( docker ps -aq --filter=name=${_container_name} )" | Out-null
    }
}

function destroy_all_docker_services() {
    Invoke-Expression 'docker ps -q | % { docker stop $_ }'
    Invoke-Expression 'docker ps -q | % { docker kill $_ }'
    Invoke-Expression 'docker ps -aq | % { docker rm $_ }'
    Invoke-Expression 'docker volume prune --force'
    Invoke-Expression 'docker system prune --force'
}

############################ Public functions end ############################

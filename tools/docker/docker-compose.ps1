. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"

############################ Public functions ############################

function docker_compose_up($_compose_filepath = "", $_env_filepath = "${project_up_dir}/.env", $_log_level = ${docker_compose_log_level}) {

    $_compose_version = (get_docker_compose_version)

    if ($_compose_version -eq "1") {
        show_success_message "Starting containers for docker-compose config '$( Split-Path -Path ${_compose_filepath} -Leaf )'" "3"
    } else {
        show_success_message "Starting containers for docker compose config '$( Split-Path -Path ${_compose_filepath} -Leaf )'" "3"
    }

    if (-not (Test-Path ${_compose_filepath} -PathType Leaf)) {
        show_error_message "Unable to start containers. Docker-compose yml file not found at path  '${_compose_filepath}', related .env file: '${_env_filepath}'."
        exit 1
    }

    if ($_env_filepath -and ! (Test-Path $_env_filepath -PathType Leaf)) {
        show_error_message "Unable to start containers. Related .env path provided but file does not exist at path '${_env_filepath}'. Compose file: '${_compose_filepath}'"
        exit 1
    }

    $_env_file_option = ""
    if (${_env_filepath}) {
        $_env_file_option = "--env-file ${_env_filepath}"
    }

    if ($_compose_version -eq "1") {
        $command = "docker-compose --file ${_compose_filepath} ${_env_file_option} --log-level ${docker_compose_log_level} up --detach"
    } else {
        # --log-level option removed as Docker break this option again and again within different releases
        $command = "docker compose --file ${_compose_filepath} ${_env_file_option} up --detach"
    }

    $env:COMPOSE_IGNORE_ORPHANS = 'true'

    Invoke-Expression $command

    $env:COMPOSE_IGNORE_ORPHANS = $null

    if ($LASTEXITCODE -ne 0) {
        show_error_message "Unable to start containers. See docker-compose output above. Process interrupted."
        show_error_message "Compose file: ${_compose_filepath}, related .env file: ${_env_filepath}."
        exit 1
    }
}

function docker_compose_stop($_compose_filepath = "", $_env_filepath = "${project_up_dir}/.env", $_log_level = ${docker_compose_log_level}) {

    $_compose_version = (get_docker_compose_version)

    if ($_compose_version -eq "1") {
        show_success_message "Stopping containers for docker-compose config '$( Split-Path -Path ${_compose_filepath} -Leaf )'" "3"
    } else {
        show_success_message "Stopping containers for docker compose config '$( Split-Path -Path ${_compose_filepath} -Leaf )'" "3"
    }

    if (-not (Test-Path ${_compose_filepath} -PathType Leaf)) {
        show_error_message "Unable to stop containers. Docker-compose yml file not found at path  '${_compose_filepath}', related .env file: '${_env_filepath}'."
        exit 1
    }

    if ($_env_filepath -and ! (Test-Path $_env_filepath -PathType Leaf)) {
        show_error_message "Unable to stop containers. Related .env path provided but file does not exist at path '${_env_filepath}'. Compose file: '${_compose_filepath}'"
        exit 1
    }

    $_env_file_option = ""
    if (${_env_filepath}) {
        $_env_file_option = "--env-file ${_env_filepath}"
    }

    if ($_compose_version -eq "1") {
        $command = "docker-compose --file ${_compose_filepath} ${_env_file_option} --log-level ${docker_compose_log_level} stop"
    } else {
        # --log-level option removed as Docker break this option again and again within different releases
        $command = "docker compose --file ${_compose_filepath} ${_env_file_option} stop"
    }

    $env:COMPOSE_IGNORE_ORPHANS = 'true'

    Invoke-Expression $command

    $env:COMPOSE_IGNORE_ORPHANS = $null

    if ($LASTEXITCODE -ne 0) {
        show_error_message "Unable to stop containers. See docker-compose output above. Process interrupted."
        show_error_message "Compose file: ${_compose_filepath}, related .env file: ${_env_filepath}."
        exit 1
    }
}

function docker_compose_down($_compose_filepath = "", $_env_filepath = "${project_up_dir}/.env", $_clean_volumes = $false, $_log_level = ${docker_compose_log_level}) {

    $_compose_version = (get_docker_compose_version)

    if ($_compose_version -eq "1") {
        show_success_message "Downing containers for docker-compose config '$( Split-Path -Path ${_compose_filepath} -Leaf )'" "3"
    } else {
        show_success_message "Downing containers for docker compose config '$( Split-Path -Path ${_compose_filepath} -Leaf )'" "3"
    }

    if (-not (Test-Path ${_compose_filepath} -PathType Leaf)) {
        show_error_message "Unable to down containers. Docker-compose yml file not found at path '${_compose_filepath}'."
        exit 1
    }

    if ($_env_filepath -and ! (Test-Path $_env_filepath -PathType Leaf)) {
        show_error_message "Unable to down containers. Related .env path provided but file does not exist at path '${_env_filepath}'. Compose file: '${_compose_filepath}'"
        exit 1
    }

    $_env_file_option = ""
    if (${_env_filepath}) {
        $_env_file_option = "--env-file ${_env_filepath}"
    }

    if ($_compose_version -eq "1") {
        if ($_clean_volumes) {
            $command = "docker-compose --file ${_compose_filepath} ${_env_file_option} --log-level ${docker_compose_log_level} down --volumes --timeout 10"
        } else {
            $command = "docker-compose --file ${_compose_filepath} ${_env_file_option} --log-level ${docker_compose_log_level} down --timeout 10"
        }
    } else {
        if ($_clean_volumes) {
            $command = "docker compose --file ${_compose_filepath} ${_env_file_option} down --volumes --timeout 10"
        } else {
            # --log-level option removed as Docker break this option again and again within different releases
            $command = "docker compose --file ${_compose_filepath} ${_env_file_option} down --timeout 10"
        }
    }

    $env:COMPOSE_IGNORE_ORPHANS = 'true'

    Invoke-Expression $command

    $env:COMPOSE_IGNORE_ORPHANS = $null

    if ($LASTEXITCODE -ne 0) {
        show_error_message "Unable to down containers. See docker-compose output above. Process interrupted.$LASTEXITCODE"
        show_error_message "Compose file: ${_compose_filepath}"
        exit 1
    }
}

function docker_compose_down_and_clean($_compose_filepath = "", $_env_filepath = "${project_up_dir}/.env", $_log_level = ${docker_compose_log_level}) {
    docker_compose_down "${_compose_filepath}" "${_env_filepath}" $true "${_log_level}"
}

function docker_compose_up_all_directory_services($_working_directory = "", $_env_filepath = "${project_up_dir}/.env", $_log_level = ${docker_compose_log_level}) {
    if (-not ${_working_directory} -or ! (Test-Path ${_working_directory} -PathType Container)) {
        show_error_message "Unable to up docker services in directory '${_working_directory}'. Working directory not found."
        exit 1
    }

    if (Test-Path "${_working_directory}/docker-compose-website.yml" -PathType Leaf) {
        docker_compose_up "${_working_directory}/docker-compose-website.yml" "${_env_filepath}" "${docker_compose_log_level}"
    }

    foreach ($_project_compose_filepath in (Get-ChildItem -Path ${_working_directory} -Filter "docker-compose-*.yml" -Exclude "docker-compose-website.yml" -Depth 1 | Select -ExpandProperty Name)) {
        docker_compose_up "${_working_directory}/${_project_compose_filepath}" "${_env_filepath}" "${docker_compose_log_level}"
    }
}

function docker_compose_stop_all_directory_services($_working_directory = "", $_env_filepath = "${project_up_dir}/.env", $_log_level = ${docker_compose_log_level}) {
    if (-not ${_working_directory} -or ! (Test-Path ${_working_directory} -PathType Container)) {
        show_error_message "Unable to stop docker services in directory '${_working_directory}'. Working directory not found."
        exit 1
    }

    foreach ($_project_compose_filepath in (Get-ChildItem -Path ${_working_directory} -Filter "docker-compose-*.yml" -Depth 1 | Select -ExpandProperty Name)) {
        docker_compose_stop "${_working_directory}/${_project_compose_filepath}" "${_env_filepath}" "${docker_compose_log_level}"
    }
}

function docker_compose_down_all_directory_services($_working_directory = "", $_env_filepath = "${project_up_dir}/.env", $_log_level = ${docker_compose_log_level}) {
    if (-not ${_working_directory} -or ! (Test-Path ${_working_directory} -PathType Container)) {
        show_error_message "Unable to down docker services in directory '${_working_directory}'. Working directory not found."
        exit 1
    }

    foreach ($_project_compose_filepath in (Get-ChildItem -Path ${_working_directory} -Filter "docker-compose-*.yml" -Depth 1 | Select -ExpandProperty Name)) {
        docker_compose_down "${_working_directory}/${_project_compose_filepath}" "${_env_filepath}" $true "${docker_compose_log_level}"
    }
}

function docker_compose_down_and_clean_all_directory_services($_working_directory = "", $_env_filepath = "${project_up_dir}/.env", $_log_level = ${docker_compose_log_level}) {
    if (-not ${_working_directory} -or ! (Test-Path ${_working_directory} -PathType Container)) {
        show_error_message "Unable to down docker services in directory '${_working_directory}'. Working directory not found."
        exit 1
    }

    foreach ($_project_compose_filepath in (Get-ChildItem -Path ${_working_directory} -Filter "docker-compose-*.yml" -Depth 1 | Select -ExpandProperty Name)) {
        docker_compose_down_and_clean "${_working_directory}/${_project_compose_filepath}" "${_env_filepath}" "${docker_compose_log_level}"
    }
}

############################ Public functions end ############################


############################ Local functions ############################

function get_docker_compose_version() {
    $_compose_version = (devbox_state_get_param_value "docker_compose_version")

    if ($_compose_version) {
      return "${_compose_version}"
    }

    if ((docker --help | Select-String "compose")) {
        devbox_state_set_param_value "docker_compose_version" "2"
        return "2"
    }

    if ((docker-compose --version | Select-String -pattern "version\ v?1\.")) {
        devbox_state_set_param_value "docker_compose_version" "1"
        return "1"
    }

    show_error_message "Docker compose version is not recognized. Please contact DevBox developers."
    exit
}

############################ Local functions end ############################
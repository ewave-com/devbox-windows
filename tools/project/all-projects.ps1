. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/project/project-state.ps1"

############################ Public functions ############################

function get_project_list($_separator = ",") {
    $_project_list = (Get-ChildItem -Path $devbox_projects_dir -Exclude "archived_projects" -Directory -Force | Sort-Object -Property Name | Select -ExpandProperty Name) -Join $_separator

    return $_project_list
}

function is_project_started($_selected_project = "", $_fast_check = $false) {
    if (-not ${_selected_project}) {
        show_error_message "Unable to check if project is started. Project name cannot be empty."
        exit 1
    }

    $_project_dir = "${devbox_projects_dir}/${_selected_project}"
    if (-not (is_project_configured $_selected_project)) {
        show_error_message "Project '${_selected_project}' is not configured. Please ensure file '${_project_dir}/.env' exists and has proper configuration values."
        show_error_message "You can copy 'config/project-defaults.env' into your project directory as '.env' and modify it as you need before starting."
        exit 1
    }

    $_project_up_dir = "${_project_dir}/docker-up"
    if (-not (Test-Path ${_project_dir} -PathType Container)) {
        return $false;
    }

    if (-not (is_state_file_exists "${_project_up_dir}") -or ((get_state_last_project_status "${_project_up_dir}") -ne "started") ) {
        return $false;
    }

    $_dotenv_project_name = (dotenv_get_param_value 'PROJECT_NAME' "${_project_dir}/.env")
    $_has_main_dotenv_file = (Test-Path "${_project_up_dir}/.env" -PathType Leaf)
    $_has_project_running_containers = if (-not $_fast_check) { (is_docker_container_running "${_dotenv_project_name}_" $false) } else { $true }
    $_docker_files_count = ((Get-ChildItem -Path "${_project_up_dir}" -Filter "docker-*.yml" -Depth 1 | Measure-Object).Count)
    $_config_dirs_count = ((Get-ChildItem -Path "${_project_up_dir}" -Directory  -Depth 1 | Measure-Object).Count)
    if (${_has_main_dotenv_file} -and ${_has_project_running_containers} -and ${_docker_files_count} -gt 0 -and ${_config_dirs_count} -gt 0) {
        return $true;
    } else {
        return $false;
    }
}

function ensure_project_configured($_selected_project = "") {
    if (-not ${_selected_project}) {
        show_error_message "Unable to check if project is configured. Project name cannot be empty."
        exit 1
    }

    $_failed = $false

    $_project_dir = "${devbox_projects_dir}/${_selected_project}"
    if (-not (Test-Path ${_project_dir} -PathType Container) -or ! (Test-Path "${_project_dir}/.env" -PathType Leaf)) {
        show_warning_message "Project '${_selected_project}' is not configured. Project file '.env' file is missing"
        $_failed = $true
    }

    if (-not $_failed) {
        # read project name from the initial file without generating of the final .env
        $_dotenv_project_name = (dotenv_get_param_value 'PROJECT_NAME' "${_project_dir}/.env")
        if (-not ${_dotenv_project_name}) {
            show_warning_message "Project '${_selected_project}' is not configured. At least param 'PROJECT_NAME' is not configured in the '${_project_dir}/.env'"
            $_failed = $true
        }
    }

    if ($_failed) {
        show_error_message "Project '${_selected_project}' is not configured. Please ensure file '${_project_dir}/.env' exists and has proper configuration values."
        show_error_message "You can copy 'config/project-defaults.env' into your project directory as '.env' and modify it as you need before starting."
        exit 1
    }
}

function is_project_configured($_selected_project = "") {
    if (-not ${_selected_project}) {
        show_error_message "Unable to check if project is configured. Project name cannot be empty."
        exit 1
    }

    $_project_dir = "${devbox_projects_dir}/${_selected_project}"
    if (-not (Test-Path ${_project_dir} -PathType Container) -or ! (Test-Path "${_project_dir}/.env" -PathType Leaf)) {
        return $false
    }

    # read project name from the initial file without generating of the final .env
    $_dotenv_project_name = (dotenv_get_param_value 'PROJECT_NAME' "${_project_dir}/.env")
    if (-not ${_dotenv_project_name}) {
        return $false
    }

    return $true;
}

############################ Public functions end ############################

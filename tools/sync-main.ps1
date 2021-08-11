# import global variables
. require_once "$devbox_root/tools/system/constants.ps1"
# import output functions (print messages)
. require_once "$devbox_root/tools/system/output.ps1"
# import common functions for all projects structure
. require_once "$devbox_root/tools/project/all-projects.ps1"
# import common functions for all projects structure
. require_once "$devbox_root/tools/docker/docker-sync.ps1"
# import common functions for all projects structure
. require_once "$devbox_root/tools/project/project-main.ps1"

############################ Public functions ############################

function start_sync($_selected_project = "") {
    init_selected_project $_selected_project
    if (-not (is_project_started $_selected_project)) {
        show_warning_message "Project '${_selected_project}' is not started for this operation."
        exit 1
    }

    docker_sync_start_all_directory_volumes "${project_up_dir}"
}

function stop_sync($_selected_project = "") {
    init_selected_project $_selected_project
    if (-not (is_project_started $_selected_project)) {
        show_warning_message "Project '${_selected_project}' is not started for this operation."
        exit 1
    }

    docker_sync_stop_all_directory_volumes "${project_up_dir}"
}

function restart_sync($_selected_project = "") {
    init_selected_project $_selected_project
    if (-not (is_project_started $_selected_project)) {
        show_warning_message "Project '${_selected_project}' is not started for this operation."
        exit 1
    }

    docker_sync_stop_all_directory_volumes "${project_up_dir}"

    docker_sync_start_all_directory_volumes "${project_up_dir}"
}

function purge_and_restart_sync($_selected_project = "") {
    init_selected_project $_selected_project
    if (-not (is_project_started $_selected_project)) {
        show_warning_message "Project '${_selected_project}' is not started for this operation."
        exit 1
    }

    docker_sync_stop_all_directory_volumes "${project_up_dir}"
    docker_sync_clean_all_directory_volumes "${project_up_dir}"

    docker_sync_start_all_directory_volumes "${project_up_dir}"
}

function open_log_window($_selected_project = "", $_selected_sync_names = "") {
    init_selected_project $_selected_project

    if (-not (is_project_started $_selected_project)) {
        show_warning_message "Project '${_selected_project}' is not started for this operation."
        exit 1
    }

    if ("${_selected_sync_names}" -eq "all") {
        $_selected_sync_names = (get_directory_sync_names "${project_up_dir}")
    }

    foreach ($_sync_name in ($_selected_sync_names.Split(','))) {
        $_related_config_path = (get_config_file_by_directory_and_sync_name "${project_up_dir}" "${_sync_name}")

        show_sync_logs_window "${_related_config_path}" "${_sync_name}"
    }
}


############################ Public functions end ############################

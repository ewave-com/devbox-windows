. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/menu/abstract-select-menu.ps1"
. require_once "${devbox_root}/tools/docker/docker-sync.ps1"

############################ Public functions ############################

function select_project_sync_name_menu($_selected_project = "") {
    if (-not $_selected_project) {
        show_error_message "Project name can not be empty to select sync"
        exit
    }

    init_selected_project "${_selected_project}"

    draw_menu_header "Project sync names"

    $_sync_names = (get_directory_sync_names "${project_up_dir}")

    $_options_str = "[Exit],All,$_sync_names"

    $_selected_item = (select_menu_item "${_options_str}")

    if (-not $_selected_item -or $_selected_item -eq "[Exit]") {
        show_success_message "Exiting selected."
        exit
    }

    if ($_selected_item -eq "All") {
        $_selected_item = 'all'
    }

    draw_menu_footer

    return $_selected_item
}

############################ Public functions end ############################

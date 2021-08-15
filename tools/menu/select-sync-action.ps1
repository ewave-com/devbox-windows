. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/menu/abstract-select-menu.ps1"

############################ Public functions ############################

function select_sync_action_menu() {
    draw_menu_header "Sync action"

    $_options_str = "[Exit],Restart sync,Stop sync,Start sync,Show logs"

    $_selected_action = (select_menu_item "${_options_str}")

    if (-not $_selected_action -or $_selected_action -eq "[Exit]") {
        show_success_message "Exiting selected."
        exit
    }

    if ($_selected_action -eq "Restart sync") {
        $_selected_action = 'restart_sync'
    } elseif ($_selected_action -eq "Stop sync") {
        $_selected_action = 'stop_sync'
    } elseif ($_selected_action -eq "Start sync") {
        $_selected_action = 'start_sync'
    } elseif($_selected_action -eq "Show logs") {
        $_selected_action = 'show_logs'
    }

    draw_menu_footer

    return $_selected_action
}

############################ Public functions end ############################

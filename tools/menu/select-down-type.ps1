. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/menu/abstract-select-menu.ps1"

############################ Public functions ############################

function select_down_type_menu() {

    draw_menu_header "Stop project menu"

    $_options_str = "Stop 1 project,Stop ALL projects,Down 1 project,Down all projects,Down and clean 1 project,Down and clean all projects,Destroy docker data[for emergency case],[Exit]"

    $_selected_type = (select_menu_item "${_options_str}")

    if (-not $_selected_type -or $_selected_type -eq "[Exit]") {
        show_success_message "Exiting selected."
        exit
    }

    if ($_selected_type -eq "Stop 1 project") {
        $_selected_type = 'stop_one'
    } elseif($_selected_type -eq "Stop ALL projects") {
        $_selected_type = 'stop_all'
    } elseif($_selected_type -eq "Down 1 project") {
        $_selected_type = 'down_one'
    } elseif($_selected_type -eq "Down and clean 1 project") {
        $_selected_type = 'down_and_clean_one'
    } elseif($_selected_type -eq "Down all projects") {
        $_selected_type = 'down_all'
    } elseif($_selected_type -eq "Down and clean all projects") {
        $_selected_type = 'down_and_clean_all'
    } elseif($_selected_type -eq "Destroy docker data[for emergency case]") {
        $_selected_type = 'docker_destroy'
    }

    draw_menu_footer

    return $_selected_type
}

############################ Public functions end ############################

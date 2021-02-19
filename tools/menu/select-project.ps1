. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/project/all-projects.ps1"
. require_once "${devbox_root}/tools/menu/abstract-select-menu.ps1"
#Set-PSDebug -strict -trace 1;
############################ Public functions ############################

function select_project_menu() {
    draw_menu_header "Select project"

    $_project_list = $( get_project_list )
    if (-not $_project_list) {
        show_error_message "Projects not found in directory ${devbox_projects_dir}. Please create project folder with required configuration files and try again."
        Exit
    }

    # add project status info to the project menu, after selecting remove appendixes from string
    $_project_list_arr = @()
    foreach ($_project_name in $_project_list.Split(",")) {
        if (-not (is_project_configured "$_project_name")) {
            $_project_name = "${_project_name} [not configured]"
        } elseif (is_project_started "$_project_name" $true) {
            $_project_name = "${_project_name} [started]"
        }

        $_project_list_arr += $_project_name
    }
    $_project_list = [string]::Join(',', $_project_list_arr)

    $_options_str = "[Exit],${_project_list}"

    $_sel_project = (select_menu_item "${_options_str}")

    if (-not $_sel_project -or $_sel_project -eq "[Exit]") {
        show_success_message "No project selected. Exiting."
        exit
    }

    $_sel_project = ${_sel_project} -Replace "\ \[started\]|\ \[not\ configured\]"

    draw_menu_footer

    return $_sel_project
}

############################ Public functions end ############################

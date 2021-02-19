#Set-PSDebug -strict -trace 1;
Set-PSDebug -strict; # uncommend this ince testing is done
$ErrorActionPreference = "Stop"

$devbox_root = $( (Split-Path -Parent $PSCommandPath) -Replace '\\', '/' )

. "$devbox_root/tools/system/require-once.ps1"

. require_once "${devbox_root}/tools/main.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/menu/select-down-type.ps1"
. require_once "${devbox_root}/tools/menu/select-project.ps1"

$_selected_project = $args[0]
$_selected_down_type = ""

if (${_selected_project}) {
    if (${_selected_project} -eq "all") {
        $_selected_down_type = "stop_all"
        $_selected_project = ""
    } else {
        $_selected_down_type = "stop_one"
    }
}

if (-not ${_selected_down_type}) {
    $_selected_down_type = (select_down_type_menu)
}

Switch -exact (${_selected_down_type}) {
    "stop_one" {
        if (-not ${_selected_project}) {
            $_selected_project = (select_project_menu)
        }
        stop_devbox_project ${_selected_project}
        break
    }
    "down_and_clean_one" {
        if (-not ${_selected_project}) {
            $_selected_project = (select_project_menu)
        }
        down_and_clean_devbox_project ${_selected_project}
        break
    }
    "stop_all" {
        stop_devbox_all
        break
    }
    "down_and_clean_all" {
        down_and_clean_devbox_all
        break
    }
    "docker_destroy" {
        docker_destroy
        break
    }
    default {
        show_error_message "Unable to parse your selection."
        exit 1
    }
}

show_success_message
show_success_message "Thank you for using DevBox and have a nice day!"

Get-Content -Path "$devbox_root/tools/print/done.txt"


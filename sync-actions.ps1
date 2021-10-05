Set-PSDebug -strict;           # Normal working mode
#Set-PSDebug -strict -trace 1; # Verbsoe debug mode

$ErrorActionPreference = "Stop"

$devbox_root = $( (Split-Path -Parent $PSCommandPath) -Replace '\\', '/' )

. "$devbox_root/tools/system/require-once.ps1"

. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/menu/select-sync-action.ps1"
. require_once "${devbox_root}/tools/menu/select-project-sync-name.ps1"
. require_once "${devbox_root}/tools/menu/select-project.ps1"
. require_once "${devbox_root}/tools/project/project-main.ps1"
. require_once "${devbox_root}/tools/sync-main.ps1"

$_selected_project = $args[0]
$_selected_sync_action = ""
$_selected_sync_name = ""

if (${_selected_project}) {
    $_selected_sync_action = "restart_sync"
}

if (-not ${_selected_sync_action}) {
    $_selected_sync_action = (select_sync_action_menu)
}

start_docker_if_not_running

Switch -exact (${_selected_sync_action}) {
    "start_sync" {
        if (-not ${_selected_project}) {
            $_selected_project = (select_project_menu)
        }
        start_sync "${_selected_project}"
        break
    }
    "stop_sync" {
        if (-not ${_selected_project}) {
            $_selected_project = (select_project_menu)
        }
        stop_sync "${_selected_project}"
        break
    }
    "restart_sync" {
        if (-not ${_selected_project}) {
            $_selected_project = (select_project_menu)
        }
        restart_sync "${_selected_project}"
        break
    }
    "show_logs" {
        if (-not ${_selected_project}) {
            $_selected_project = (select_project_menu)
        }
        if (-not ${_selected_sync_name}) {
            $_selected_sync_name = (select_project_sync_name_menu ${_selected_project})
        }
        open_log_window "${_selected_project}" "${_selected_sync_name}"
        break
    }
    default {
        show_error_message "Unknown sync action."
        exit 1
    }
}

show_success_message "Sync operation finished!"

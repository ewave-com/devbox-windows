Set-PSDebug -strict;           # Normal working mode
#Set-PSDebug -strict -trace 1; # Verbsoe debug mode

$ErrorActionPreference = "Stop"

$devbox_root = $( (Split-Path -Parent $PSCommandPath) -Replace '\\', '/' )

. "$devbox_root/tools/system/require-once.ps1"

. require_once "$devbox_root/tools/system/dependencies-installer.ps1"
. require_once "$devbox_root/tools/main.ps1"
. require_once "$devbox_root/tools/menu/select-project.ps1"

# https://patorjk.com/software/taag/#p=display&f=Doom&t=eWave%20DevBox
Get-Content -Path "$devbox_root/tools/print/logo.txt"

install_dependencies
update_docker_images_if_required

# You can pass project name as argument to start without additional selecting
$_selected_project = $args[0]
# Select folder with project
if (-not ${_selected_project}) {
    $_selected_project = (select_project_menu)
}

$_no_iteraction = $false
if ($args[1] -eq "-n" -or $args[1] -eq "--no-interaction") {
    $_no_iteraction = $true
}

start_devbox_project "${_selected_project}" $_no_iteraction

Get-Content -Path "$devbox_root/tools/print/done.txt"





. require_once "$devbox_root/tools/system/constants.ps1"

############################ Public functions ############################

function get_wsl_path($path) {
    $wsl_path = ((Resolve-Path $path) -Replace '\\', '/')
    $wsl_path = (wsl -d ${devbox_wsl_distro_name} wslpath $wsl_path)

    return $wsl_path
}

############################ Public functions end ############################

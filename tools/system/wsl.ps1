############################ Public functions ############################

function get_wsl_path($path) {
    $wsl_path = ((Resolve-Path $path) -Replace '\\', '/')
    $wsl_path = (wsl wslpath $wsl_path)

    return $wsl_path
}

############################ Public functions end ############################

. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"

$devbox_state_file_name = "devbox.state"

############################ Public functions ############################

# check if param is presented in the devbox state file
function devbox_state_has_param($_param_name = "") {
    $_state_filepath=(get_devbox_state_file_path)

    devbox_state_init_file
    devbox_state_ensure_param_is_readable "${_param_name}"

    $_param_value = (devbox_state_get_param_value ${_param_name})
    if ($_param_value) {
        return $true
    } else {
        return $false
    }
}

# get value the devbox state file by the param name
function devbox_state_get_param_value($_param_name = "") {
    $_state_filepath=(get_devbox_state_file_path)

    $_param_value=''

    if (-not (is_devbox_state_file_exists)) {
        return ${_param_value}
    }

    devbox_state_ensure_param_is_readable "${_param_name}"

    if ((Get-Content -Path "${_state_filepath}" | Select-String -Pattern "^${_param_name}=" | Select -First 1)) {
        $_param_value = ((Get-Content -Path "${_state_filepath}" | Select-String -Pattern "^${_param_name}=" | Select -First 1).toString().Split('=')[1])
    }

    return "${_param_value}"
}

# set value in the devbox state file by the param name
function devbox_state_set_param_value($_param_name = "", $_param_value = "") {
    $_state_filepath=(get_devbox_state_file_path)

    devbox_state_init_file
    devbox_state_ensure_param_is_readable "${_param_name}"

    $_param_presented=$(devbox_state_has_param "${_param_name}")
    if (${_param_presented}) {
        (Get-Content "${_state_filepath}") -Replace "^${_param_name}=.*", "${_param_name}=${_param_value}" | Set-Content -Path "${_state_filepath}"
    } else {
        Add-Content -Path ${_state_filepath} -Value "${_param_name}=${_param_value}"
    }
}

# get time of last update of docker images
function get_devbox_state_docker_images_updated_at() {
    $_status=$(devbox_state_get_param_value "docker_images_updated_at")

    return ${_status}
}

# set time of last update of docker images
function set_devbox_state_docker_images_updated_at($_value = "") {
    devbox_state_set_param_value "docker_images_updated_at" "${_value}"

    return
}

# get time in seconds since last update, current timestamp if last time is missing
function get_devbox_state_docker_images_updated_at_diff() {
    $_current_timestamp=([int](Get-Date -UFormat %s -Millisecond 0))
    $_last_updated_timestamp=$(get_devbox_state_docker_images_updated_at)

    if (-not "${_last_updated_timestamp}" ) {
        return "${_current_timestamp}"
    }

    return $((${_current_timestamp} - ${_last_updated_timestamp}))
}

############################ Public functions end ############################

############################ Local functions ############################

# initialize state file if missing
function devbox_state_init_file() {
    $_state_filepath=(get_devbox_state_file_path)

    if (-not (Test-Path "${_state_filepath}" -PathType Leaf)) {
        New-Item -Path "${_state_filepath}" -Force | Out-Null
    }
}

# check param name is presented and checked file exists
function devbox_state_ensure_param_is_readable($_param_name = "") {
    $_state_filepath=(get_devbox_state_file_path)

    if (-not ${_param_name}) {
        show_error_message "Unable to read DevBox state parameter. Param name cannot be empty"
        exit 1
    }

    if (-not $_state_filepath -or -not (Test-Path "${_state_filepath}" -PathType Leaf)) {
        show_error_message "Unable to read DevBox state param. State file does not exist at path '${_state_filepath}'."
        exit 1
    }
}

# return devbox state file path
function get_devbox_state_file_path() {
    $_state_filepath="${devbox_root}/${devbox_state_file_name}"

    return "${_state_filepath}";
}

# check if DevBox state file exists
function is_devbox_state_file_exists() {
    $_state_filepath=(get_devbox_state_file_path)

    if (Test-Path "${_state_filepath}" -PathType Leaf) {
        return $true
    } else {
        return $false
    }
}

############################ Local functions end ############################

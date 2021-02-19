. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"

############################ Public functions ############################

# Function which exports variable from ENV file
function dotenv_export_variables($_env_filepath = "") {
    if (-not "${_env_filepath}" -or -not (Test-Path "${_env_filepath}" -PathType Leaf)) {
        show_error_message "Unable to export .env params. File doesn't exist at path '${_env_filepath}'."
        exit 1
    }

    $_param_lines = (Get-Content -Path "$_env_filepath" | Select-String -Pattern '(^$)|(^#)' -NotMatch | Select -ExpandProperty Line)

    # put each param to global variables
    $_param_lines | ForEach {
        $_param_arr = $_.ToString().Split('=');
        Set-Variable -Name ${_param_arr}[0] -Value "$( ${_param_arr}[1] )" -Scope Global
    }
}

# Function which unset variable from ENV file
function dotenv_unset_variables($_env_filepath = "") {
    if (-not "${_env_filepath}" -or -not (Test-Path "${_env_filepath}" -PathType Leaf)) {
        show_error_message "Unable to unset .env params. File doesn't exist at path '${_env_filepath}'."
        exit 1
    }

    $_param_lines = (Get-Content -Path "$_env_filepath" | Select-String -Pattern '(^$)|(^#)' -NotMatch | Select -ExpandProperty Line)
    $_param_lines | ForEach {
        $_param_arr = $_.ToString().Split('=');
        Remove-Variable -Name ${_param_arr}[0] -Scope Global -ErrorAction SilentlyContinue
    }
}

# check if param is presented in the given .env file
function dotenv_has_param($_param_name = "", $_env_filepath = "${current_env_filepath}") {
    dotenv_ensure_param_is_readable "${_param_name}" "${_env_filepath}"

    $_param_presented = (Get-Content -Path "${_env_filepath}" | Select-String -Pattern "^${_param_name}=")
    if (${_param_presented}) {
        return $true
    } else {
        return $false
    }
}

# check if param has not empty value in the given .env file
function dotenv_has_param_value($_param_name = "", $_env_filepath = "${current_env_filepath}") {
    dotenv_ensure_param_is_readable "${_param_name}" "${_env_filepath}"

    $_param_value = (dotenv_get_param_value ${_param_name} ${_env_filepath})
    if (${_param_value}) {
        return $true
    } else {
        return $false
    }
}

# get value the given .env file by the param name
function dotenv_get_param_value($_param_name = "", $_env_filepath = "${current_env_filepath}") {
    dotenv_ensure_param_is_readable "${_param_name}" "${_env_filepath}"

    $_param_value = ""
    if ((Get-Content -Path "${_env_filepath}" | Select-String -Pattern "^${_param_name}=" | Select -First 1)) {
        $_param_value = ((Get-Content -Path "${_env_filepath}" | Select-String -Pattern "^${_param_name}=" | Select -First 1).toString().Split('=')[1])
    }

    return $_param_value
}

# set value the given .env file by the param name
function dotenv_set_param_value($_param_name = "", $_param_value = "", $_env_filepath = "${current_env_filepath}") {
    dotenv_ensure_param_is_readable "${_param_name}" "${_env_filepath}"

    $_param_presented = (dotenv_has_param "${_param_name}" "${_env_filepath}")
    if (${_param_presented}) {
        (Get-Content "${_env_filepath}") -Replace "^${_param_name}=.*", "${_param_name}=${_param_value}" | Set-Content -Path "${_env_filepath}"
    } else {
        Add-Content -Path ${_env_filepath} -Value "${_param_name}=${_param_value}"
    }
}

# replace file patterns '{{_PARAM_NAME_}}' with corresponding values from .env file
function replace_file_patterns_with_dotenv_params($_filepath = "", $_env_filepath = "${current_env_filepath}") {
    if (-not (${_filepath})) {
        show_error_message "Unable to replace config value at path '${_filepath}'. Path can not be empty."
        exit 1
    }

    if (-not (Test-Path "${_filepath}" -PathType Leaf)) {
        show_error_message "Unable to replace patterns with env params at path '${_filepath}'. Path does not exist!"
        exit 1
    }

    $_unprocessed_pattern_found = $false

    foreach ($_pattern in (Get-Content -Path "${_filepath}" | Select-String -Pattern "(\{\{[A-Za-z0-9_-]*\}\})" -AllMatches | ForEach-Object -MemberName Matches | ForEach-Object { $_.Groups[1].Value })) {
        $_param_name = ($_pattern -Replace '{|}', '')

        # read variable from exported shell variables if exists
        try {
            $_param_value = (Get-Variable -Scope Global -Name $_param_name -ValueOnly)
        } catch {
            $_param_value = $null
        }

        if ($_param_value -ne $null) {
            replace_value_in_file "${_filepath}" "${_pattern}" "${_param_value}"
            continue
        }

        # search for pattern variable in project .env file if presented
        $_param_presented = (dotenv_has_param "${_param_name}" "${_env_filepath}")
        if ($_param_presented) {
            $_param_value = $( dotenv_get_param_value "${_param_name}" "${_env_filepath}" )
            replace_value_in_file "${_filepath}" "${_pattern}" "${_param_value}"
            continue
        }

        $_unprocessed_pattern_found = $true
        show_warning_message "Unprocessed pattern '${_pattern}' found at path '${_filepath}'"
    }

    if (${_unprocessed_pattern_found}) {
        show_error_message "Not all patterns were prepared at path '${_filepath}'."
        show_error_message "Ensure all required params are presented in .env file or contact DevBox developers."
        exit 1
    }
}

# replace patterns '{{_PARAM_NAME_}}' in all directory files with corresponding values from .env file
function replace_directory_files_patterns_with_dotenv_params($_dir_path = "", $_env_filepath = "${current_env_filepath}") {
    if (! "${_dir_path}") {
        show_error_message "Unable to replace directory files with dotenv variables. Directory path cannot be empty."
        exit 1
    }

    if (-not (Test-Path "${_dir_path}" -PathType Container)) {
        show_error_message "Unable to replace directory files with dotenv variables. Directory does not exist at path '${_dir_path}'."
        exit 1
    }

    # remove trailing slash
    $_dir_path = ($_dir_path -Replace "/$")

    foreach ($_config_path in (Get-ChildItem -Path $_dir_path -Recurse -File | Select -ExpandProperty FullName)) {
        # rename file if it has a ".pattern" extension
        if (($_config_path.Substring($_config_path.Length - 8)) -eq ".pattern") {
            $_new_config_path = ($_config_path.Substring(0, $_config_path.Length - 8))
            Move-Item -Path $_config_path -Destination $_new_config_path -Force
            $_config_path = "${_new_config_path}"
        }

        replace_file_patterns_with_dotenv_params "${_config_path}" "${_env_filepath}"
    }
}

############################ Public functions end ############################

############################ Local functions ############################

# check param name is presented and checked file exists
function dotenv_ensure_param_is_readable($_param_name = "", $_env_filepath = "${current_env_filepath}") {
    if (-not ${_param_name}) {
        show_error_message "Unable to read .env value. Param name cannot be empty"
        exit 1
    }

    if (-not $_env_filepath -or -not (Test-Path "${_env_filepath}" -PathType Leaf)) {
        show_error_message "Unable to read .env param. Project .env file doesn't exist at path '${_env_filepath}'."
        exit 1
    }
}

############################ Local functions end ############################

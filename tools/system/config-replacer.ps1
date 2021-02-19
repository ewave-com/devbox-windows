. require_once "${devbox_root}/tools/system/output.ps1"

############################ Public functions ############################

function replace_value_in_file($_filepath = "", $_needle = "", $_replacement = "") {

    if (-not $_filepath) {
        show_error_message "Unable to replace config value at path '${_filepath}'. Path can not be empty."
        exit 1
    }

    if (-not (Test-Path $_filepath -PathType Leaf)) {
        show_error_message "Unable to replace config value at path '${_filepath}'. Path does not exist! Needle '${_needle}', replacement '${_replacement}'"
        exit 1
    }

    if (-not $_needle) {
        show_error_message "Unable to replace config value at path '${_filepath}'. Needle can not be empty!"
        exit 1
    }

    (Get-Content $_filepath) -Replace $_needle, $_replacement | Set-Content -Path $_filepath
}

############################ Public functions end ############################

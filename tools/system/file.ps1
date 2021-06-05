. require_once "$devbox_root/tools/system/output.ps1"

############################ Public functions ############################

function copy_path($_from_path = "", $_to_path = "") {
    if (-not $_from_path) {
        show_error_message "Unable to copy source file '${_from_path}'. Path can not be empty. Debug info: Target path '${_to_path}'"
        exit 1
    }

    #  Any,Container,Leaf
    if (-not (Test-Path $_from_path -PathType Any)) {
        show_error_message "Unable to copy file '${_from_path}'. Source path does not exist!"
        exit 1
    }

    if ((Test-Path $_from_path -PathType Container) -and (Test-Path $_to_path -PathType Leaf)) {
        show_error_message "Unable to copy directory into file. Debug info: source path - '${_from_path}', target path - '${_to_path}'"
    }

    if ((Test-Path $_from_path -PathType Leaf) -and (Test-Path $_to_path -PathType Container)) {
        $_to_path = "${_to_path}/"
    }

    New-Item -ItemType directory -Path (Split-Path -Path $_to_path) -Force | Out-Null

    if ((Test-Path $_from_path -PathType Container) -and (Test-Path $_to_path -PathType Container)) {
        Copy-Item -Path "${_from_path}/*" -Destination "${_to_path}" -Recurse -Force
    }
    else {
        Copy-Item -Path "${_from_path}" -Destination "${_to_path}" -Recurse -Force
    }
}

function copy_path_with_project_fallback($_source_path = "", $_target_path = "", $_strict_mode = $true) {
    $_is_copied=$false

    if (Test-Path "${devbox_root}/${_source_path}" -PathType Any) {
        copy_path "${devbox_root}/${_source_path}" "${_target_path}"
        $_is_copied=$true
    }

    if (Test-Path "${project_dir}/${_source_path}" -PathType Any) {
        copy_path "${project_dir}/${_source_path}" "${_target_path}"
        $_is_copied=$true
    }

    if (-not $_is_copied -and $_strict_mode) {
        show_error_message "Unable to copy file: source path '${devbox_root}/${_source_path}' does not exist! Alternative fallback path also not found: '${project_dir}/${_source_path}'"
    } else {
        return
    }
}

# Replace '\r\n\' endings with '\n'
function replace_file_line_endings($_filepath = "") {
    if (-not (Test-Path ${_filepath} -PathType Leaf)) {
        show_error_message "Unable to replace line endings. Target file doesn't exist at path '${_filepath}'."
        exit 1
    }

    $text = [IO.File]::ReadAllText(${_filepath}) -replace "`r`n", "`n"
    [IO.File]::WriteAllText(${_filepath}, $text)
}

############################ Public functions end ############################

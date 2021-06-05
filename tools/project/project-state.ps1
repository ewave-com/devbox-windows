#!/usr/bin/env bash

$state_file_name="project.state"

############################ Public functions ############################

# check if project state file exists
function is_state_file_exists($_state_filepath = "${project_up_dir}/${state_file_name}") {
  if (Test-Path $_state_filepath -PathType Container) {
    $_state_filepath = "${_state_filepath}/${state_file_name}"
  }

  if (Test-Path $_state_filepath -PathType Leaf) {
    return $true
  }

  return $false
}

# get hash of project dotenv file for comparison
function get_state_dotenv_hash($_state_filepath = "${project_up_dir}/${state_file_name}") {
  $_stored_dotenv_hash = (state_get_param_value "dotenv_hash" "${_state_filepath}")

  return "${_stored_dotenv_hash}"
}

# save hash of project dotenv file
function set_state_dotenv_hash($_value = "", $_state_filepath = "${project_up_dir}/${state_file_name}") {

    if (-not $_value) {
        $_value = (Get-FileHash -Algorithm MD5 "${project_dir}/.env").Hash
    }

    state_set_param_value "dotenv_hash" "${_value}" "${_state_filepath}"

    return
}

# get last project status, available values: empty, "starting", "started", "stopping", "stopped"
function get_state_last_project_status($_state_filepath = "${project_up_dir}/${state_file_name}") {
  $_status = (state_get_param_value "project_status" "${_state_filepath}")

  return ${_status}
}

# save project status, available values: "starting", "started", "stopping", "stopped"
function set_state_last_project_status($_value = "", $_state_filepath = "${project_up_dir}/${state_file_name}") {

  state_set_param_value "project_status" "${_value}" "${_state_filepath}"

  return
}

function remove_state_file($_state_filepath = "${project_up_dir}/${state_file_name}") {
    if (Test-Path  $_state_filepath -PathType Container) {
        $_state_filepath = "${_state_filepath}/${state_file_name}"
    }

    if (Test-Path  $_state_filepath -PathType Leaf) {
        Remove-Item $_state_filepath -Force | Out-Null
    }
}

############################ Public functions end ############################

############################ Local functions ############################

# check if param is presented in the given state file
function state_has_param($_param_name = "", $_state_filepath = "${project_up_dir}/${state_file_name}") {
    if (Test-Path $_state_filepath -PathType Container) {
        $_state_filepath = "${_state_filepath}/${state_file_name}"
    }

    init_state_file "${_state_filepath}"
    state_ensure_param_is_readable "${_param_name}" "${_state_filepath}"

    $_param_presented = (Get-Content -Path "${_state_filepath}" | Select-String -Pattern "^${_param_name}=")
    if (${_param_presented}) {
        return $true
    } else {
        return $false
    }
}

# get value the given state file by the param name
function state_get_param_value($_param_name = "", $_state_filepath = "${project_up_dir}/${state_file_name}") {
    if (Test-Path $_state_filepath -PathType Container) {
        $_state_filepath = "${_state_filepath}/${state_file_name}"
    }

    $_param_value = ''

    if (-not (is_state_file_exists $_state_filepath)) {
        return "${_param_value}"
    }

    state_ensure_param_is_readable "${_param_name}" "${_state_filepath}"

    if ((Get-Content -Path "${_state_filepath}" | Select-String -Pattern "^${_param_name}=" | Select -First 1)) {
        $_param_value = ((Get-Content -Path "${_state_filepath}" | Select-String -Pattern "^${_param_name}=" | Select -First 1).toString().Split('=')[1])
    }

    return "${_param_value}"
}

# set value in the given state file by the param name
function state_set_param_value($_param_name = "", $_param_value = "", $_state_filepath = "${project_up_dir}/${state_file_name}") {
    if (Test-Path $_state_filepath -PathType Container) {
        $_state_filepath = "${_state_filepath}/${state_file_name}"
    }

    init_state_file "${_state_filepath}"
    state_ensure_param_is_readable "${_param_name}" "${_state_filepath}"

    $_param_presented = (state_has_param "${_param_name}" "${_state_filepath}")
    if (${_param_presented}) {
        (Get-Content "${_state_filepath}") -Replace "^${_param_name}=.*", "${_param_name}=${_param_value}" | Set-Content -Path "${_state_filepath}"
    } else {
        Add-Content -Path ${_state_filepath} -Value "${_param_name}=${_param_value}"
    }
}

# initialize state file if missing
function init_state_file($_state_filepath = "${project_up_dir}/${state_file_name}") {
    if (Test-Path $_state_filepath -PathType Container) {
        $_state_filepath = "${_state_filepath}/${state_file_name}"
    }

    if (-not (Test-Path $_state_filepath -PathType Leaf)) {
        New-Item -ItemType File -Path "${_state_filepath}" -Force | Out-Null
    }
}

# check param name is presented and checked file exists
function state_ensure_param_is_readable($_param_name = "", $_state_filepath = "${project_up_dir}/${state_file_name}") {
    if (Test-Path $_state_filepath -PathType Container) {
        $_state_filepath = "${_state_filepath}/${state_file_name}"
    }

    if (-not (${_param_name})) {
        show_error_message "Unable to read project state parameter. Param name cannot be empty"
        exit 1
    }

    if (-not (${_state_filepath}) -or -not(Test-Path $_state_filepath -PathType Leaf)) {
        show_error_message "Unable to read project state param. State file does not exist at path '${_state_filepath}'."
        exit 1
    }
}

############################ Local functions end ############################

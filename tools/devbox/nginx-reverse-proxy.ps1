. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/system/file.ps1"

############################ Public functions ############################

function nginx_reverse_proxy_restart() {
    Invoke-Expression "docker restart nginx-reverse-proxy" | Out-Null
}

function nginx_reverse_proxy_add_website($_website_config_path = "", $_crt_file_name = "", $_key_file_name = "") {
    nginx_reverse_proxy_prepare_common_folders

    nginx_reverse_proxy_add_website_config "${_website_config_path}"

    if (${_crt_file_name}) {
        nginx_reverse_proxy_add_website_ssl_cert "${_crt_file_name}" "${_key_file_name}"
    }
}

function nginx_reverse_proxy_remove_project_website($_website_host_name = "", $_crt_file_name = "") {

    if (-not ${_website_host_name}) {
        show_error_message "Unable to remove nginx revers-proxy website. Website host name cannot be empty."
        exit 1
    }

    nginx_reverse_proxy_prepare_common_folders

    nginx_reverse_proxy_remove_website_config "${_website_host_name}.conf"
    nginx_reverse_proxy_remove_website_logs "${_website_host_name}"

    if (${_crt_file_name}) {
        nginx_reverse_proxy_remove_website_ssl_cert "${_crt_file_name}"
    }
}

############################ Public functions end ############################

############################ Local functions ############################

function nginx_reverse_proxy_prepare_common_folders() {
    New-Item -ItemType Directory -Path "${devbox_infra_dir}/nginx-reverse-proxy/run" -Force | Out-Null

    New-Item -ItemType Directory -Path "${devbox_infra_dir}/nginx-reverse-proxy/run/conf.d/" -Force | Out-Null
    New-Item -ItemType Directory -Path "${devbox_infra_dir}/nginx-reverse-proxy/run/logs/" -Force | Out-Null
    New-Item -ItemType Directory -Path "${devbox_infra_dir}/nginx-reverse-proxy/run/ssl/" -Force | Out-Null
}

function nginx_reverse_proxy_add_website_config($_website_config_path = "") {

    if (-not ${_website_config_path}) {
        show_error_message "Unable to add nginx revers-proxy website. Source path of website config cannot be empty."
        exit 1
    }

    copy_path "${_website_config_path}" "${devbox_infra_dir}/nginx-reverse-proxy/run/conf.d/"
}

function nginx_reverse_proxy_remove_website_config($_website_config_filename = "") {

    if (-not ${_website_config_filename}) {
        show_error_message "Unable to remove nginx revers-proxy website config. Source path of website config cannot be empty."
        exit 1
    }

    if (Test-Path "${devbox_infra_dir}/nginx-reverse-proxy/run/conf.d/${_website_config_filename}" -PathType Leaf) {
        Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/conf.d/${_website_config_filename}" -Force
    }

    if (Test-Path "${devbox_infra_dir}/nginx-reverse-proxy/run/conf.d/${_website_config_filename}.conf" -PathType Leaf) {
        Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/conf.d/${_website_config_filename}.conf" -Force
    }
}

function nginx_reverse_proxy_add_website_ssl_cert($_source_crt_path = "", $_source_key_path = "") {
    if (-not ${_source_crt_path}) {
        show_error_message "Unable to add nginx revers-proxy SSL certificate. Source path of certificate cannot be empty."
        exit 1
    }

    copy_path "${_source_crt_path}" "${devbox_infra_dir}/nginx-reverse-proxy/run/ssl/"

    if (-not ${_source_key_path}) {
        $_source_key_path="$( Split-Path -Path $_source_crt_path )/$((Get-Item $_source_crt_path).BaseName).key"
    }

    if (${_source_key_path}) {
        copy_path "${_source_key_path}" "${devbox_infra_dir}/nginx-reverse-proxy/run/ssl/"
    }
}

function nginx_reverse_proxy_remove_website_ssl_cert($_crt_file_name = "", $_key_file_name = "") {

    if (-not ${_crt_file_name}) {
        show_error_message "Unable to remove nginx revers-proxy SSL certificate. File name cannot be empty."
        exit 1
    }

    if (Test-Path "${devbox_infra_dir}/nginx-reverse-proxy/run/ssl/${_crt_file_name}" -PathType Leaf) {
        Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/ssl/${_crt_file_name}" -Force
    }

    if (-not ${_key_file_name}) {
        $_key_file_name = [System.IO.Path]::GetFileNameWithoutExtension($_crt_file_name)
    }

    if (Test-Path "${devbox_infra_dir}/nginx-reverse-proxy/run/ssl/${_key_file_name}" -PathType Leaf) {
        Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/ssl/${_key_file_name}" -Force
    }
}

function nginx_reverse_proxy_remove_website_logs($_website_host_name = "") {
    if (-not ${_website_host_name}) {
        show_error_message "Unable to remove nginx revers-proxy website logs. Website host name cannot be empty."
        exit 1
    }

    Remove-Item "${devbox_infra_dir}/nginx-reverse-proxy/run/logs/*${_website_host_name}.log" -Force | Out-Null
}

############################ Local functions end ############################

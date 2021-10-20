. require_once "${devbox_root}/tools/system/file.ps1"
. require_once "${devbox_root}/tools/system/dotenv.ps1"
. require_once "${devbox_root}/tools/devbox/nginx-reverse-proxy.ps1"
. require_once "${devbox_root}/tools/system/ssl.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"

############################ Public functions ############################

function prepare_project_nginx_reverse_proxy_configs() {
    if ("${WEBSITE_PROTOCOL}" -ne "http" -and "${WEBSITE_PROTOCOL}" -ne "https") {
        show_error_message "Website protocol must be either http or https. Please check WEBSITE_PROTOCOL in you .env file."
        exit 1
    }

    # prepare http.conf.pattern or https.conf.pattern within docker-up directory as '${WEBSITE_HOST_NAME}.conf'
    $_nginx_proxy_config_filepath = "${project_up_dir}/nginx-reverse-proxy/conf.d/${WEBSITE_HOST_NAME}.conf"
    copy_path_with_project_fallback "configs/nginx-reverse-proxy/${CONFIGS_PROVIDER_NGINX_PROXY}/conf.d/${WEBSITE_PROTOCOL}.conf.pattern" "${_nginx_proxy_config_filepath}"

    $_proxy_pass_container_name = if (${VARNISH_ENABLE} -eq "yes") { "${CONTAINER_VARNISH_NAME}" } else { "${CONTAINER_WEB_NAME}" }
    replace_value_in_file "${project_up_dir}/nginx-reverse-proxy/conf.d/${WEBSITE_HOST_NAME}.conf" "{{web_container_name}}" "${_proxy_pass_container_name}"

    $_website_nginx_extra_host_names = ''
    if ("${WEBSITE_EXTRA_HOST_NAMES}") {
        $_website_nginx_extra_host_names = (${WEBSITE_EXTRA_HOST_NAMES} -Replace ',', ' ')
    }
    replace_value_in_file "${_nginx_proxy_config_filepath}" "{{website_extra_host_names_nginx_list}}" "${_website_nginx_extra_host_names}"

    replace_file_patterns_with_dotenv_params "${_nginx_proxy_config_filepath}"

    # Create ssl directory as it is common synced docker volume
    New-Item -ItemType Directory -Path "${project_up_dir}/configs/ssl/" -Force | Out-Null

    if (${WEBSITE_PROTOCOL} -eq 'http') {
        nginx_reverse_proxy_add_website "${_nginx_proxy_config_filepath}"
        return
    }

    if (${WEBSITE_PROTOCOL} -eq 'https') {
        # find or generate certificate in ${project_up_dir}/configs/ssl
        prepare_website_ssl_certificate
        ssl_add_system_certificate "${project_up_dir}/configs/ssl/${WEBSITE_SSL_CERT_FILENAME}.crt" "CN=${WEBSITE_HOST_NAME}*"

        nginx_reverse_proxy_add_website "${_nginx_proxy_config_filepath}" "${project_up_dir}/configs/ssl/${WEBSITE_SSL_CERT_FILENAME}.crt"
    }
}

function cleanup_project_nginx_reverse_proxy_configs($_full_clean = $false) {
    if (${WEBSITE_PROTOCOL} -eq 'http') {
        nginx_reverse_proxy_remove_project_website "${WEBSITE_HOST_NAME}"
        return
    }

    if (${WEBSITE_PROTOCOL} -eq 'https') {
        if ($_full_clean) {
            nginx_reverse_proxy_remove_project_website "${WEBSITE_HOST_NAME}" "${WEBSITE_SSL_CERT_FILENAME}.crt"

            ssl_delete_system_certificate "${WEBSITE_SSL_CERT_FILENAME}.crt" "CN=${WEBSITE_HOST_NAME}*"
        } else {
            nginx_reverse_proxy_remove_project_website "${WEBSITE_HOST_NAME}"
        }
    }
}

############################ Public functions end ############################

############################ Local functions ############################

function prepare_website_ssl_certificate() {
    copy_path_with_project_fallback "configs/ssl/${CONFIGS_PROVIDER_SSL}/${WEBSITE_SSL_CERT_FILENAME}.crt" "${project_up_dir}/configs/ssl/${WEBSITE_SSL_CERT_FILENAME}.crt" $false
    copy_path_with_project_fallback "configs/ssl/${CONFIGS_PROVIDER_SSL}/${WEBSITE_SSL_CERT_FILENAME}.key" "${project_up_dir}/configs/ssl/${WEBSITE_SSL_CERT_FILENAME}.key" $false

    if (-not (Test-Path "${project_up_dir}/configs/ssl/${WEBSITE_SSL_CERT_FILENAME}.crt" -PathType Leaf)) {
        $_extra_domains = if (-not ${WEBSITE_EXTRA_HOST_NAMES}) { "" } else { "${WEBSITE_EXTRA_HOST_NAMES}" }

        $_ssl_dir = "${devbox_infra_dir}/nginx-reverse-proxy/run/ssl"
        if ((-not (Test-Path "${_ssl_dir}/DevboxRootCA.crt" -PathType Leaf)) -or (-not (Test-Path "${_ssl_dir}/DevboxRootCA.pem" -PathType Leaf)) -or (-not (Test-Path "${_ssl_dir}/DevboxRootCA.key" -PathType Leaf)))
        {
            ssl_generate_root_certificate_authority "${_ssl_dir}/DevboxRootCA.crt"
            ssl_add_system_certificate "${_ssl_dir}/DevboxRootCA.crt" "CN=DevboxRootCA*" $true

            show_success_message "Devbox Root CA has been generated and imported to your system."
            show_warning_message "If you still see the warning about insecure connection in your browser please import the certificate authority to your browser. "
            show_warning_message "Root CA Path: ${_ssl_dir}/DevboxRootCA.crt"
        }

        ssl_generate_domain_certificate "${WEBSITE_HOST_NAME}" "$_extra_domains" "${project_up_dir}/configs/ssl/${WEBSITE_SSL_CERT_FILENAME}.crt" "${project_up_dir}/configs/ssl/${WEBSITE_SSL_CERT_FILENAME}.key" "${_ssl_dir}/DevboxRootCA.pem"
    }

    if (-not (Test-Path "${project_up_dir}/configs/ssl/${WEBSITE_SSL_CERT_FILENAME}.crt" -PathType Leaf)) {
        show_error_message "Unable to apply HTTPS. Certificate is missing."
        show_error_message "Please ensure certificate files exist in common and project configs at path 'configs/ssl/${CONFIGS_PROVIDER_SSL}/${WEBSITE_SSL_CERT_FILENAME}.crt'"
        exit 1
    }
}

############################ Local functions end ############################

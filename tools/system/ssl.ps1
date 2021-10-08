. require_once ${devbox_root}/tools/system/output.ps1
. require_once ${devbox_root}/tools/docker/docker.ps1

############################ Public functions ############################

function ssl_import_new_system_certificate($_cert_source_path) {
    add_system_ssl_certificate "${_cert_source_path}"
}

function ssl_disable_system_certificate($_cert_source_path) {
    ssl_remove_system_certificate "${_cert_source_path}"
}


function ssl_generate_root_certificate_authority($_target_root_crt_path, $_target_root_key_path) {
    if (-not $_target_root_crt_path) {
        show_error_message "Unable to generate Root CA certificate. Target path of certificate cannot be empty."
        exit 1
    }

    $_cert_basename = [System.IO.Path]::GetFileNameWithoutExtension($_target_root_crt_path)
    if (-not $_target_root_key_path) {
        $_target_root_key_path = "$( Split-Path -Path $_target_root_crt_path )/$_cert_basename.key"
    }
    $_target_root_pem_path = "$( Split-Path -Path $_target_root_crt_path )/$_cert_basename.pem"

    New-Item -ItemType directory -Path (Split-Path -Path $_target_root_crt_path) -Force | Out-Null

    if (is_docker_container_running 'nginx-reverse-proxy') {
        $_openssl_command="mkdir -p /tmp/DevboxRootCA && " +
          "openssl req -x509 " +
          "-nodes -new -sha256 -days 1024 " +
          "-newkey rsa:2048 " +
          "-keyout /tmp/DevboxRootCA/${_cert_basename}.key " +
          "-out /tmp/DevboxRootCA/${_cert_basename}.pem " +
          "-subj /C=BY/ST=Minsk/L=Minsk/O=EwaveDevOpsTeam_Devbox/ " +
          ">/dev/null 2>&1 && " +
          "openssl x509 -outform pem -in /tmp/DevboxRootCA/${_cert_basename}.pem -out /tmp/DevboxRootCA/${_cert_basename}.crt " +
          ">/dev/null 2>&1"

        docker exec -it 'nginx-reverse-proxy' /bin/bash -c "${_openssl_command}"

        if (-not ($?)) {
          show_error_message "Unable to generate Root CA certificate. An error occurred during generation."
          exit 1
        }

        docker cp "nginx-reverse-proxy:/tmp/DevboxRootCA/${_cert_basename}.crt" "${_target_root_crt_path}"
        docker cp "nginx-reverse-proxy:/tmp/DevboxRootCA/${_cert_basename}.pem" "${_target_root_pem_path}"
        docker cp "nginx-reverse-proxy:/tmp/DevboxRootCA/${_cert_basename}.key" "${_target_root_key_path}"
        docker exec -it 'nginx-reverse-proxy' /bin/bash -c "rm -rf /tmp/DevboxRootCA"
    } else {
        show_error_message "Unable to generate Root CA certificate. Nginx-reverse-proxy container for generating is not running."
        exit 1
    }
}


function ssl_generate_domain_certificate($_website_name, $_extra_domains, $_target_crt_path, $_target_key_path, $_root_ca_pem_path, $_root_ca_key_path) {
    if (-not $_website_name) {
        show_error_message "Unable to generate website SSL certificate. Website name cannot be empty."
        exit 1
    }

    if (-not $_target_crt_path) {
        show_error_message "Unable to generate website SSL certificate. Target path of certificate cannot be empty."
        exit 1
    }

    if (-not $_target_crt_path) {
        show_error_message "Unable to generate website SSL certificate. Root CA cannot be empty."
        exit 1
    }

    $_cert_basename = [System.IO.Path]::GetFileNameWithoutExtension($_target_crt_path)

    if (-not $_target_key_path) {
        $_target_key_path = "$( Split-Path -Path $_target_crt_path )/$_cert_basename.key"
    }

    $_root_ca_basename = [System.IO.Path]::GetFileNameWithoutExtension($_root_ca_pem_path)
    if (-not $_root_ca_key_path) {
        $_root_ca_key_path = "$( Split-Path -Path $_root_ca_pem_path )/$_root_ca_basename.key"
    }

    New-Item -ItemType directory -Path (Split-Path -Path $_target_crt_path) -Force | Out-Null

    if (is_docker_container_running 'nginx-reverse-proxy') {
        $_ext_content = "authorityKeyIdentifier=keyid,issuer\n" +
                        "basicConstraints=CA:FALSE\n" +
                        "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment\n" +
                        "subjectAltName = @alt_names\n" +
                        "${_ext_content}[alt_names]\n" +
                        "${_ext_content}DNS.1 = ${_website_name}"

        if ($_extra_domains.Split(",")) {
            $_counter = 2
            foreach ($_domain in ($_extra_domains.Split(","))) {
                $_ext_content = "${_ext_content}\nDNS.${_counter} = ${_domain}"
                $_counter++
            }
        }

        docker cp "${_root_ca_pem_path}" "nginx-reverse-proxy:/tmp/DevBoxRootCa.pem"
        docker cp "${_root_ca_key_path}" "nginx-reverse-proxy:/tmp/DevBoxRootCa.key"

        $_openssl_command = "[ ! -f /root/.rnd ] && openssl rand -writerand /root/.rnd >/dev/null 2>&1 || true; " +
            "echo -e '${_ext_content}' > /tmp/${_website_name}.ext && " +
            "openssl req -new -nodes " +
            "  -newkey rsa:2048 " +
            "  -keyout /tmp/${_cert_basename}.key " +
            "  -out /tmp/${_cert_basename}.csr " +
            "  -subj '/C=BY/ST=Minsk/L=Minsk/O=EwaveDevOpsTeam_Devbox/CN=${_website_name}' " +
            ">/dev/null 2>&1 && " +
            "openssl x509 -req " +
            "  -sha256 " +
            "  -days 1024 " +
            "  -in /tmp/${_cert_basename}.csr " +
            "  -CA /tmp/DevBoxRootCa.pem " +
            "  -CAkey /tmp/DevBoxRootCa.key " +
            "  -CAcreateserial " +
            "  -extfile /tmp/${_website_name}.ext " +
            "  -out /tmp/${_cert_basename}.crt " +
            ">/dev/null 2>&1"

        docker exec -it 'nginx-reverse-proxy' /bin/bash -c "${_openssl_command}"

        if (-not ($?)) {
          show_error_message "Unable to generate CA certificate. An error occurred during generation. See command output above."
          exit 1
        }

        docker cp "nginx-reverse-proxy:/tmp/${_cert_basename}.crt" "$_target_crt_path"
        docker cp "nginx-reverse-proxy:/tmp/${_cert_basename}.key" "$_target_key_path"
        docker exec -it 'nginx-reverse-proxy' /bin/bash -c "rm -f /tmp/{${_cert_basename}.crt,${_cert_basename}.key,${_cert_basename}.csr,${_cert_basename}.ext,DevBoxRootCa.pem,DevBoxRootCa.key,DevBoxRootCa.srl}"
    } else {
        show_error_message "Unable to generate CA certificate. Nginx-reverse-proxy container for generating is not running."
        exit 1
    }
}
#
# function ssl_generate_domain_certificate($_website_name = "", $_target_crt_path = "", $_target_key_path = "") {
#     # todo check doc about self-signed certificates
#     #https://medium.com/better-programming/how-to-create-trusted-ssl-certificates-for-your-local-development-13fd5aad29c6
#     #https://medium.com/better-programming/trusted-self-signed-certificate-and-local-domains-for-testing-7c6e6e3f9548
#     if (-not $_website_name) {
#         show_error_message "Unable to generate CA certificate. Website name cannot be empty."
#         exit 1
#     }
#
#     if (-not $_target_crt_path) {
#         show_error_message "Unable to generate CA certificate. Target path of certificate cannot be empty."
#         exit 1
#     }
#
#     $_cert_basename = [System.IO.Path]::GetFileNameWithoutExtension($_target_crt_path)
#     if (-not $_target_key_path) {
#         $_target_key_path = "$( Split-Path -Path $_target_crt_path )/$_cert_basename.key"
#     }
#
#     New-Item -ItemType directory -Path (Split-Path -Path $_target_crt_path) -Force | Out-Null
#
#     # use reverse-proxy container to avoid ssl software installation and as this infrastructure container is avaiable for generating
#     if (is_docker_container_running 'nginx-reverse-proxy') {
#         $_openssl_command = "[ ! -f /root/.rnd ] && openssl rand -writerand /root/.rnd; " +
#                 "openssl req -x509 -nodes " +
#                 "-newkey ec:<(openssl ecparam -name secp384r1) " +
#                 "-keyout /tmp/${_cert_basename}.key " +
#                 "-out /tmp/${_cert_basename}.crt " +
#                 "-days 365 " +
#                 "-subj '/C=BY/ST=Minsk/L=Minsk/O=DevOpsTeam_EWave/CN=${_website_name}' " +
#                 " >/dev/null # 2>&1"
#
#         docker exec -it 'nginx-reverse-proxy' /bin/bash -c "${_openssl_command}"
#
#         docker cp "nginx-reverse-proxy:/tmp/$_cert_basename.crt" "$_target_crt_path"
#         docker cp "nginx-reverse-proxy:/tmp/$_cert_basename.key" "$_target_key_path"
#         docker exec -it 'nginx-reverse-proxy' /bin/bash -c "rm /tmp/$_cert_basename.crt /tmp/$_cert_basename.key"
#     } else {
#         show_error_message "Unable to generate CA certificate. Nginx-reverse-proxy container for generating is not running."
#         Exit 1
#     }
# }

############################ Public functions end ############################

############################ Local functions ############################

function add_system_ssl_certificate($_cert_source_path = "") {
    if (-not $_cert_source_path) {
        show_error_message "Unable to add CA certificate. Filename cannot be empty."
        exit 1
    }

    if (-not (Test-Path $_cert_source_path -PathType Leaf)) {
        show_error_message "Unable to add CA certificate. Cert file does not exist at path '${_cert_source_path}'."
        exit 1
    }

    Start-Process PowerShell -Wait -Verb RunAs -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass", "certutil -addstore -f 'ROOT' $_cert_source_path"
}

function ssl_remove_system_certificate($_file_name = "", $_website_name = "") {
    if ((-not $_file_name) -and (-not $_website_name)) {
        show_error_message "Unable to remove CA certificate. Filename cannot be empty."
        exit 1
    }

    if ($_website_name) {
        $_thumbprint = (Get-ChildItem -path cert: -Recurse | where { $_.Subject -like "CN=$_website_name" } | Select Thumbprint)
        Start-Process PowerShell -Wait -Verb RunAs -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass", "certutil -delstore -f 'ROOT' $_thumbprint"
        exit 1
    }
}

############################ Local functions end ############################

. require_once ${devbox_root}/tools/system/output.ps1

############################ Public functions ############################

# Function which find free port for mysql service
function get_available_mysql_port() {
    $_containers_port = $(find_port_across_docker_containers "34[0-9]{2}")
    $_netstat_port = $(find_port_by_regex "34[0-9]{2}")

    if (-not $_containers_port -and -not $_netstat_port) {
        $_result_port = 3400
    } else {
        # find highest port across docker containers ports and netstat ports by mask and allocate the next one
        $_result_port = ([int]((Get-Variable -name _containers_port,_netstat_port | Sort -Descending Value | Select -First 1).Value) + 1)
    }

    return $_result_port
}

function get_mysql_port_from_existing_container($_container_name = "") {
    if (-not $_container_name) {
        show_error_message "Unable to check mysql port from existing container. Container name cannot be empty"
        exit 1
    }

    $_container_port = (find_port_across_docker_containers "34[0-9]{2}" ${_container_name})

    return $_container_port
}

# Function which checks if mysql port is available to be exposed
function ensure_mysql_port_is_available($_checked_port = "", $_container_name = '') {
    if (-not $_checked_port) {
        show_error_message "Unable to check mysql port. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free

    $_used_port = (find_port_by_regex "$_checked_port")
    if ($_checked_port -eq $_used_port) {
        $_process_info = (get_process_info_by_allocated_port ${_checked_port})
        #  if container name given then skip error if the checked allocated port belongs to the same container
        if ((-not $_container_name) -or (-not($_process_info | Select-String -Pattern ${_container_name}))) {
            show_error_message "MYSQL port ${_checked_port} is already allocated by process ${_process_info}"
            show_error_message "Please free the port, set port CONTAINER_MYSQL_PORT to another value or set it empty for autocompleting in '${project_dir}/.env' file"
            exit 1
        }
    }

    if (($_checked_port -lt 3306) -or $_checked_port -gt 3499) {
        show_error_message "MYSQL port must be configured in range 3306-3499. Value '${_checked_port}' given. Please update value in your '${project_dir}/.env' file."
        exit 1
    }
}

# Function which find free port for elasticsearch service
function get_available_elasticsearch_port() {
    $_containers_port = $(find_port_across_docker_containers "92[0-9]{2}")
    $_netstat_port = $(find_port_by_regex "92[0-9]{2}")

    if (-not $_containers_port -and -not $_netstat_port) {
        $_result_port = 9200
    } else {
        # find highest port across docker containers ports and netstat ports by mask and allocate the next one
        $_result_port = ([int]((Get-Variable -name _containers_port,_netstat_port | Sort -Descending Value | Select -First 1).Value) + 1)
    }

    return $_result_port
}

function get_elasticsearch_port_from_existing_container($_container_name = "") {
    if (-not $_container_name) {
        show_error_message "Unable to check elasticsearch port from existing container. Container name cannot be empty"
        exit 1
    }

    $_container_port = (find_port_across_docker_containers "92[0-9]{2}" ${_container_name})

    return $_container_port
}

# Function which checks if elasticsearch port is available to be exposed
function ensure_elasticsearch_port_is_available($_checked_port = "", $_container_name = $null) {
    if (-not $_checked_port) {
        show_error_message "Unable to check elasticsearch port. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free
    $_used_port = (find_port_by_regex $_checked_port)
    if ($_checked_port -eq $_used_port) {
        $_process_info=(get_process_info_by_allocated_port ${_checked_port})
        #  if container name given then skip error if the checked allocated port belongs to the same container
        if ((-not $_container_name) -or (-not($_process_info | Select-String -Pattern ${_container_name}))) {
            show_error_message "ElasticSearch port ${_checked_port} is already allocated by process ${_process_info}"
            show_error_message "Please free the port, set port CONTAINER_ELASTICSEARCH_PORT to another value or set it empty for autocompleting in '${project_dir}/.env' file"
            exit 1
        }
    }

    if (($_checked_port -lt 9200) -or $_checked_port -gt 9399) {
        show_error_message "ElasticSearch port must be configured in range 9200-9399. Value '${_checked_port}' given. Please update value in your '${project_dir}/.env' file."
        exit 1
    }
}


# Function which find free port for rabbitmq service
function get_available_rabbitmq_port() {
    $_containers_port = $(find_port_across_docker_containers "56[0-9]{2}")
    $_netstat_port = $(find_port_by_regex "56[0-9]{2}")

    if (-not $_containers_port -and -not $_netstat_port) {
        $_result_port = 5672
    } else {
        # find highest port across docker containers ports and netstat ports by mask and allocate the next one
        $_result_port = ([int]((Get-Variable -name _containers_port,_netstat_port | Sort -Descending Value | Select -First 1).Value) + 1)
    }

    return $_result_port
}

function get_rabbitmq_port_from_existing_container($_container_name = "") {
    if (-not $_container_name) {
        show_error_message "Unable to check rabbitmq port from existing container. Container name cannot be empty"
        exit 1
    }

    $_container_port = (find_port_across_docker_containers "56[0-9]{2}" ${_container_name})

    return $_container_port
}

# Function which checks if rabbitmq port is available to be exposed
function ensure_rabbitmq_port_is_available($_checked_port = "", $_container_name = $null) {
    if (-not $_checked_port) {
        show_error_message "Unable to check rabbitmq port. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free
    $_used_port = (find_port_by_regex $_checked_port)
    if ($_checked_port -eq $_used_port) {
        $_process_info=(get_process_info_by_allocated_port ${_checked_port})
        #  if container name given then skip error if the checked allocated port belongs to the same container
        if ((-not $_container_name) -or (-not($_process_info | Select-String -Pattern ${_container_name}))) {
            show_error_message "RabbitMQ port ${_checked_port} is already allocated by process ${_process_info}"
            show_error_message "Please free the port, set port CONTAINER_RABBITMQ_PORT to another value or set it empty for autocompleting in '${project_dir}/.env' file"
            exit 1
        }
    }

    if (($_checked_port -lt 5600) -or $_checked_port -gt 5699) {
        show_error_message "RabbitMQ port must be configured in range 5600-5699. Value '${_checked_port}' given. Please update value in your '${project_dir}/.env' file."
        exit 1
    }
}

# Function which find free ssh port for website
function get_available_website_ssh_port() {
    $_containers_port = $(find_port_across_docker_containers "23[0-9]{2}")
    $_netstat_port = $(find_port_by_regex "23[0-9]{2}")

    if (-not $_containers_port -and -not $_netstat_port) {
        $_result_port = 2300
    } else {
        # find highest port across docker containers ports and netstat ports by mask and allocate the next one
        $_result_port = ([int]((Get-Variable -name _containers_port,_netstat_port | Sort -Descending Value | Select -First 1).Value) + 1)
    }

    return $_result_port
}

function get_website_ssh_port_from_existing_container($_container_name = "") {
    if (-not $_container_name) {
        show_error_message "Unable to check website ssh port from existing container. Container name cannot be empty"
        exit 1
    }

    $_container_port = (find_port_across_docker_containers "23[0-9]{2}" ${_container_name})

    return $_container_port
}

# Function which checks if website ssh port is available to be exposed
function ensure_website_ssh_port_is_available($_checked_port = "", $_container_name = '') {
    if (-not $_checked_port) {
        show_error_message "Unable to check website ssh port. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free
    $_used_port = (find_port_by_regex $_checked_port)
    if ($_checked_port -eq $_used_port) {
        $_process_info=(get_process_info_by_allocated_port ${_checked_port})
        #  if container name given then skip error if the checked allocated port belongs to the same container
        if ((-not $_container_name) -or (-not($_process_info | Select-String -Pattern ${_container_name}))) {
            show_error_message "Website ssh port ${_checked_port} is already allocated by process ${_process_info}"
            show_error_message "Please free the port, set port CONTAINER_WEB_SSH_PORT to another value or set it empty for autocompleting in '${project_dir}/.env' file"
            exit 1
        }
    }

    if (($_checked_port -lt 2300) -or $_checked_port -gt 2499) {
        show_error_message "Website ssh port must be configured in range 2300-2499. Value '${_checked_port}' given. Please update value in your '${project_dir}/.env' file."
        exit 1
    }
}

# Function which find free port for service
function ensure_port_is_available($_checked_port = "") {
    if (-not $_checked_port) {
        show_error_message "Unable to check port availability. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free
    $_used_port = (find_port_by_regex $_checked_port)
    if ($_checked_port -eq $_used_port) {
        $_process_info=(get_process_info_by_allocated_port ${_checked_port})
        show_error_message "Unable to allocate port '${_checked_port}' as it is already in use by process ${_process_info}. Please free the port and try again."
        exit 1
    }
}

function get_process_info_by_allocated_port($_checked_port = "") {
    if (-not $_checked_port) {
        show_error_message "Unable to check port allocation. Port number argument cannot be empty"
        exit 1
    }

    $_port_mask = (get_port_full_search_mask ${_checked_port})

    $_pid = (netstat -ano | Select-String "LISTENING" | Select-String -Pattern $_port_mask | ForEach { $_.ToString().Split('', [System.StringSplitOptions]::RemoveEmptyEntries)[4] } | Select -First 1)
    if ($_pid) {
        $_pname = (Get-Process -Id $_pid | Select -First 1 | ForEach { echo $_.ProcessName } )
        if ($_pname | Select-String -Pattern "docker") {
            $_container = Invoke-Expression "docker ps -a --filter='publish=${_checked_port}' --filter=status=running --format='{{.Names}}'"
            return "PID: ${_pid}; Process name: '${_pname}'; Docker container name: '${_container}'"
        }

        return "PID: ${_pid}; Process name: '${_pname}'"
    }

    return ""
}

function find_port_across_docker_containers($_checked_port = "", $_container_name = "") {
    if (-not $_checked_port) {
        show_error_message "Unable to check port allocation. Port number argument cannot be empty"
        exit 1
    }

    $_containers_port = ''
    if (-not $_container_name) {
        if (docker ps -aq) {
            $_containers_port = (Invoke-Expression "docker inspect --format='{{json .HostConfig.PortBindings}}' ( docker ps -aq)" | ForEach { ($_ | ConvertFrom-Json).PSObject.Properties | ForEach { $_.Value.HostPort } } | Select-String -Pattern "^${_checked_port}$" | ForEach-Object -MemberName Line | Sort -Descending | Select -First 1)
        }
    } else {
        $_containers_port = (Invoke-Expression "docker inspect --format='{{json .HostConfig.PortBindings}}' ${_container_name}" | ForEach { ($_ | ConvertFrom-Json).PSObject.Properties | ForEach { $_.Value.HostPort } } | Select-String -Pattern "^${_checked_port}$" | ForEach-Object -MemberName Line | Sort -Descending | Select -First 1)
    }

  return $_containers_port
}

############################ Public functions end ############################

############################ Local functions ############################

function find_port_by_regex($_port_mask = "") {
    if (-not $_port_mask) {
        show_error_message "Unable to find available port by empty mask."
        exit 1
    }

    $_port_mask = (get_port_full_search_mask ${_port_mask})

    $_port = (netstat -ano | Select-String "LISTENING" | Select-String -Pattern $_port_mask | ForEach { $_.ToString().Split('', [System.StringSplitOptions]::RemoveEmptyEntries)[1].split(':')[1] } | Sort -Descending | Select -First 1)

    return [int]$_port
}

function get_port_full_search_mask($_port_mask = "") {
    if (-not $_port_mask) {
        show_error_message "Unable to find available port by empty mask."
        exit 1
    }
    # if mask is only numbers - prepend possible hosts to clarify output
    if (-not ($_port_mask -match '^:')) {
        $_port_mask = "'(\*\:$_port_mask\s)|(:::$_port_mask\s)|(0\.0\.0\.0:$_port_mask\s)|(127\.0\.0\.1:$_port_mask\s)"
    }

    return ${_port_mask}
}

############################ Local functions end ############################

. require_once ${devbox_root}/tools/system/output.ps1

############################ Public functions ############################

# Function which find free port for mysql service
function get_available_mysql_port() {
    $_port = (find_port_by_regex "340[0-9]{1}")

    if (-not $_port) {
        $_port = 3400
    } else {
        $_port = ($_port + 1)
    }

    return $_port
}

# Function which checks if mysql port is available to be exposed
function ensure_mysql_port_is_available($_checked_port = "") {
    if (-not $_checked_port) {
        show_error_message "Unable to check mysql port. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free

    $_used_port = (find_port_by_regex "$_checked_port")
    if ($_checked_port -eq $_used_port) {
        show_error_message "MYSQL port $_checked_port is in use"
        show_error_message "Please set port CONTAINER_MYSQL_PORT to another value of set it empty for autocompleting in '${project_dir}/.env' file"
        exit 1
    }

    if (($_checked_port -lt 3306) -or $_checked_port -gt 3499) {
        show_error_message "MYSQL port must be configured in range 3306-3499. Value '${_checked_port}' given. Please update value in your '${project_dir}/.env' file."
        exit 1
    }
}

# Function which find free port for elasticsearch service
function get_available_elasticsearch_port() {
    $_port = (find_port_by_regex "920[0-9]{1}")

    if (-not $_port) {
        $_port = 9200
    } else {
        $_port = ($_port + 1)
    }

    return $_port
}

# Function which checks if elasticsearch port is available to be exposed
function ensure_elasticsearch_port_is_available($_checked_port = "") {
    if (-not $_checked_port) {
        show_error_message "Unable to check elasticsearch port. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free
    $_used_port = (find_port_by_regex $_checked_port)
    if ($_checked_port -eq $_used_port) {
        show_error_message "ElasticSearch port $_checked_port is in use"
        show_error_message "Please set port CONTAINER_ELASTICSEARCH_PORT to another value of set it empty for autocompleting in '${project_dir}/.env' file"
        exit 1
    }

    if (($_checked_port -lt 9200) -or $_checked_port -gt 9399) {
        show_error_message "ElasticSearch port must be configured in range 9200-9399. Value '${_checked_port}' given. Please update value in your '${project_dir}/.env' file."
        exit 1
    }
}

# Function which find free ssh port for website
function get_available_website_ssh_port() {
    $_port = (find_port_by_regex "230[0-9]{1}")

    if (-not $_port) {
        $_port = 2300
    } else {
        $_port = ($_port + 1)
    }

    return $_port
}

# Function which checks if website ssh port is available to be exposed
function ensure_website_ssh_port_is_available($_checked_port = "") {
    if (-not $_checked_port) {
        show_error_message "Unable to check website ssh port. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free
    $_used_port = (find_port_by_regex $_checked_port)
    if ($_checked_port -eq $_used_port) {
        show_error_message "Website ssh port $_checked_port is in use"
        show_error_message "Please set port CONTAINER_WEB_SSH_PORT to another value of set it empty for autocompleting in '${project_dir}/.env' file"
        exit 1
    }

    if (($_checked_port -lt 2300) -or $_checked_port -gt 2499) {
        show_error_message "Website ssh port must be configured in range 2300-2499. Value '${_checked_port}' given. Please update value in your '${project_dir}/.env' file."
        exit 1
    }
}

# Function which find free port for elasticsearch service
function ensure_port_is_available($_checked_port = "") {
    if (-not $_checked_port) {
        show_error_message "Unable to check port availability. Port number argument cannot be empty"
        exit 1
    }

    # Check the given mysql port is free
    $_used_port = (find_port_by_regex $_checked_port)
    if ($_checked_port -eq $_used_port) {
        show_error_message "Unable to allocate port '${_checked_port}' as it is already in use. Please free the port and try again."
        exit 1
    }
}

############################ Public functions end ############################

############################ Local functions ############################

function find_port_by_regex($_port_mask = "") {

    if (-not $_port_mask) {
        show_error_message "Unable to find available port by empty mask."
        exit 1
    }

    # if mask is only numbers - prepend possible hosts to clarify output
    if (-not ($_port_mask -match '^:')) {
        $_port_mask = "'(\*\:$_port_mask\s)|(:::$_port_mask\s)|(0\.0\.0\.0:$_port_mask\s)|(127\.0\.0\.1:$_port_mask\s)"
    }

    $_port = (netstat -ano | Select-String "LISTENING" | Select-String -Pattern $_port_mask | ForEach { $_.ToString().Split('', [System.StringSplitOptions]::RemoveEmptyEntries)[1].split(':')[1] } | Sort -Descending | Select -First 1)

    return [int]$_port
}

############################ Local functions end ############################

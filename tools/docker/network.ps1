$devbox_network_name = "docker_projectsubnetwork"

############################ Public functions ############################

function create_docker_network() {
    $_network_presented = Invoke-Expression "docker network ls --filter='name=${devbox_network_name}' --format='{{.Name}}'"

    if (-not $_network_presented) {
        Invoke-Expression "docker network create ${devbox_network_name}" | Out-Null
    }
}

function remove_docker_network() {
    $_network_presented = Invoke-Expression "docker network ls --filter='name=${devbox_network_name}' --format='{{.Name}}'"

    if ($_network_presented) {
        Invoke-Expression "docker network rm ${devbox_network_name}" | Out-Null
    }
}

function get_docker_network_name() {
    return ${devbox_network_name}
}

############################ Public functions end ############################

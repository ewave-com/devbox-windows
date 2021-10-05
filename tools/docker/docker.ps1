. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"

############################ Public functions ############################

function get_docker_container_state($_container_name = "") {
    if (-not $_container_name) {
        show_error_message "Unable to get docker container state. Container name cannot be empty."
        exit 1
    }

    $_result = Invoke-Expression "docker ps -a --filter='name=^${_container_name}$' --format='{{.State}}'"

    return $_result
}

function is_docker_container_running($_container_name = "", $_find_exact_match = $true) {
    if (-not $_container_name) {
        show_error_message "Unable to check active docker containers. Container name cannot be empty."
        exit 1
    }

    if ($_find_exact_match) {
        $_container_name="^${_container_name}$"
    }

    $_result = Invoke-Expression "docker ps -a --filter='name=${_container_name}' --filter=status=running --format='{{.Names}}'"
    if ($_result) {
        return $true
    } else {
        return $false
    }
}

function is_docker_container_exist($_container_name = "", $_find_exact_match = $true) {
    if (-not $_container_name) {
        show_error_message "Unable to check existing docker container. Container name cannot be empty."
        exit 1
    }

    if ($_find_exact_match) {
        $_container_name="^${_container_name}$"
    }

    $_result = Invoke-Expression "docker ps -a --filter='name=${_container_name}' --format='{{.Names}}'"
    if ($_result) {
        return $true
    } else {
        return $false
    }
}

function stop_container_by_name($_container_name = "", $_find_exact_match = $true) {
    if (-not $_container_name) {
        show_error_message "Unable to stop docker container. Container name cannot be empty."
        exit 1
    }

    if ($_find_exact_match) {
        $_container_name="^${_container_name}$"
    }

    Invoke-Expression "docker stop (docker ps -q --filter='name=${_container_name}') --time 10" | Out-null
}

function kill_container_by_name($_container_name = "", $_signal = "SIGKILL", $_find_exact_match = $true) {
    if (-not $_container_name) {
        show_error_message "Unable to kill docker container. Container name cannot be empty."
        exit 1
    }

    if ($_find_exact_match) {
        $_container_name="^${_container_name}$"
    }

    Invoke-Expression "docker kill (docker ps -aq --filter='name=${_container_name}') -s ${_signal}" | Out-null
}

function rm_container_by_name($_container_name = "", $_force = $false, $_find_exact_match = $true) {
    if (-not $_container_name) {
        show_error_message "Unable to remove docker container. Container name cannot be empty."
        exit 1
    }

    if ($_find_exact_match) {
        $_container_name="^${_container_name}$"
    }

    if ($_force) {
        Invoke-Expression "docker rm ( docker ps -aq --filter=name=${_container_name} ) --force" | Out-null
    } else {
        Invoke-Expression "docker rm ( docker ps -aq --filter=name=${_container_name} )" | Out-null
    }
}

function destroy_all_docker_services() {
    Invoke-Expression 'docker ps -q | % { docker stop $_ }'
    Invoke-Expression 'docker ps -q | % { docker kill $_ }'
    Invoke-Expression 'docker ps -aq | % { docker rm $_ }'
    Invoke-Expression 'docker volume prune --force'
    Invoke-Expression 'docker system prune --force'
}


function start_docker_if_not_running() {
    if (-not (Get-Process 'com.docker.proxy' -ErrorAction Ignore)) {
        if (Test-Path "$Env:ProgramFiles\Docker\Docker\Docker for Windows.exe" -PathType Leaf) {
            show_success_message "Starting Docker application" "2"
            Start-Process -FilePath "$Env:ProgramFiles\Docker\Docker\Docker for Windows.exe"
        } elseif (Test-Path "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe" -PathType Leaf) {
            show_success_message "Starting Docker application" "2"
            Start-Process -FilePath "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        } else {
            show_error_message "Unable to find current Docker location to start. Please run Docker manually and try to start devbox again."
            Exit 1
        }
    }

    try {
        Invoke-Expression "docker ps" *> $null -ErrorAction SilentlyContinue
    } catch { }
    if ($LASTEXITCODE -ne 0) {
        show_success_message "Waiting for Docker start completion. Please wait..."
        $_docker_running = $false
        $_attempts = 0
        $_start_timeout_sec=30
        While ($_docker_running -ne $true) {
            Write-Host -NoNewline "."
            try {
                Invoke-Expression "docker ps" *>$null -ErrorAction SilentlyContinue
            } catch { }
            $exit_code = $LASTEXITCODE

            if ($exit_code -ne 0) {
                $_attempts += 1
                Start-Sleep 1
            } else {
                $_docker_running = $true
            }

            if ($_attempts -ge 30) {
                show_error_message "Docker starting process exceeded ${_start_timeout_sec} seconds timeout. Please start docker manually and try again"
                exit 1
            }
        }
        Write-Host "Done"
    }

}

############################ Public functions end ############################

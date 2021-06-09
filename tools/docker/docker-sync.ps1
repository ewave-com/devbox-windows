. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"
. require_once "${devbox_root}/tools/system/wsl.ps1"
. require_once "${devbox_root}/tools/docker/docker.ps1"

############################ Public functions ############################

# start syncing and watching the changes, currently strategy unison only is available for windows
function docker_sync_start($_config_file = "", $_sync_name = "", $_show_logs = $true, $_with_health_check = $true) {
    if (-not ($_config_file) -or ! (Test-Path $_config_file -PathType Leaf)) {
        show_error_message "Unable to start syncing. Docker-sync yml file not found at path  '${_config_file}'."
        exit 1
    }

    if (-not $_sync_name) {
        $_sync_names = (get_config_file_sync_names "${_config_file}")
    } else {
        $_sync_names = @($_sync_name)
    }

    $_working_dir = $( get_config_file_working_dir "${_config_file}" )
    $_show_logs_for_syncs = (get_config_file_option ${_config_file} 'devbox_show_logs_for_syncs')

    $_sync_strategy=(get_config_file_sync_strategy ${_config_file})

    # start syncs using explicit docker-sync sync name to have separate daemon pid file and logging for each sync
    foreach ($_sync_name in $_sync_names) {
        if ($_sync_strategy -ne "native") {
            if (-not (is_docker_container_exist ${_sync_name})) {
                show_success_message "Starting initial synchronization for sync name '${_sync_name}'. Please wait" "3"
            } else {
                show_success_message "Starting background synchronization for sync name '${_sync_name}'" "3"
            }
        }

        if (-not (Test-Path "${_working_dir}/${_sync_name}.log")) {
            New-Item -ItemType File -Path "${_working_dir}/${_sync_name}.log" -Force | Out-Null
        }

        Add-Content -Path "${_working_dir}/${_sync_name}.log" -Value "[$( Get-Date )] Starting synchronization..."

        if (${_show_logs} -and (${_show_logs_for_syncs} | Select-String -Pattern "${_sync_name}") -and "${_sync_strategy}" -ne "native") {
            show_success_message "Opening logs window for sync ${_sync_name}" "3"
            show_sync_logs_window ${_config_file} ${_sync_name}
        }

        if ($preferred_sync_env -eq "wsl") {
            $wsl_log_path = $( get_wsl_path "${_working_dir}/${_sync_name}.log" )
            #            Write-Host "wsl -d ${devbox_wsl_distro_name} bash --login -c `"DOCKER_SYNC_SKIP_UPDATE=1 docker-sync start --config='$(get_wsl_path ${_config_file})' --sync-name='${_sync_name}' --dir='$(get_wsl_path ${_working_dir})' --app_name='${_sync_name}'`" >> '${_working_dir}/${_sync_name}.log'`""
            wsl -d ${devbox_wsl_distro_name} bash --login -c "DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK=1 DOCKER_SYNC_SKIP_UPDATE=1 docker-sync start --config='$( get_wsl_path ${_config_file} )' --sync-name='${_sync_name}' --dir='$( get_wsl_path ${_working_dir} )' --app_name='${_sync_name}' >> '${wsl_log_path}'"
        } elseif ($preferred_sync_env -eq "cygwin") {
            # [Start-Job] is a bit tricky here, but we need to start cygwin bash process as background job but wait for finishing with logging in current window
            # generally it looks like detached 'nohup' process but with synchronous ruuning, Otherwise internal ruby process might fail earlier than required, to-do investigate error more deep
            # Error example: [ASYNC BUG] consume_communication_pipe: read(2)     EBADF       [NOTE]      You may have encountered a bug in the Ruby interpreter or extension libraries.
            # Command example: & C:\cygwin64\bin\bash.exe --login -c "DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK=1 docker-sync start --config='${_config_file}' --sync-name='${_sync_name}' --dir='${_working_dir}' --app_name='${_sync_name}'"
            # Direct calls using [& \bash.exe], [Start-Process], [Invoke-Expression] dosn't work properly because of error above
            # In addition we redirect error thread to the regualr output as cygwin detects some docker output as error and interrupts with failed exit code, generally this is docker issue
            Start-Job -Name "sync_start:${_sync_name}" {
                & "${Using:cygwin_dir}\bin\bash.exe" --login -c "DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK=1 DOCKER_SYNC_SKIP_UPDATE=1 docker-sync start --config='${Using:_config_file}' --sync-name='${Using:_sync_name}' --dir='${Using:_working_dir}' --app_name='${Using:_sync_name}' 2>&1 >> '${Using:_working_dir}/${Using:_sync_name}.log'"
            } | Receive-Job -Wait
        }

        if (-not ($?)) {
            show_error_message "Unable to start sync volumes. See docker-sync output above. Process interrupted. Exit code: '$?'"
            show_error_message "Sync config file: ${_config_file}."
            Throw "Docker-sync start error"
        }
    }

    if (${_with_health_check} -and ${_sync_strategy} -ne "native") {
        start_background_health_checker ${_config_file}
    }
}

# stop syncing and watching the changes, stop command terminate all config syncs so sync_name is omited
function docker_sync_stop($_config_file = "", $_kill_service_processes = $true) {
    if (-not ($_config_file) -or ! (Test-Path $_config_file -PathType Leaf)) {
        show_error_message "Unable to stop syncing. Docker-sync yml file not found at path  '${_config_file}'."
        exit 1
    }

    $_sync_strategy=(get_config_file_sync_strategy ${_config_file})

    if ($_sync_strategy -ne "native") {
        show_success_message "Stopping docker-sync for all syncs from config '$( Split-Path -Path ${_config_file} -Leaf )'" "3"
    }

    # terminate health-checker background processes
    if ($_kill_service_processes -and (${_sync_strategy} -ne "native")) {
        stop_background_health_checker $_config_file
    }

    $_working_dir = (get_config_file_working_dir "${_config_file}")
    if (-not (Test-Path "${_working_dir}/${_sync_name}.log")) {
        New-Item -ItemType File -Path "${_working_dir}/common.log" -Force | Out-Null
    }

    if ($preferred_sync_env -eq "wsl") {
        wsl -d ${devbox_wsl_distro_name} bash --login -c "DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK=1 docker-sync stop --config='$( get_wsl_path ${_config_file} )' > /dev/null"
    } elseif ($preferred_sync_env -eq "cygwin") {
        Start-Job -Name "sync_stop:${_sync_name}" {
            & "${Using:cygwin_dir}\bin\bash.exe" --login -c "DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK=1 docker-sync stop --config='${Using:_config_file}' > /dev/null"
        } | Receive-Job -Wait
    }

    if (-not ($?)) {
        show_error_message "Unable to stop sync volumes. See docker-sync output above. Process interrupted. Exit code: '$?'"
        show_error_message "Sync config file: ${_config_file}."
        Throw "Docker-sync stop error"
    }

    if ($_kill_service_processes -and (${_sync_strategy} -ne "native")) {
        close_sync_logs_window ${_config_file}
    }
}

# cleanup volumes data, volumes will be emptied, should be called after stopping in case problems occurred or for final shutdowning of project
function docker_sync_clean($_config_file = "", $_sync_name = "") {
    if (-not ($_config_file) -or ! (Test-Path $_config_file -PathType Leaf)) {
        show_error_message "Unable to clean syncs. Docker-sync yml file not found at path  '${_config_file}'."
        exit 1
    }

    if (-not $_sync_name) {
        $_sync_names = (get_config_file_sync_names "${_config_file}")
    } else {
        $_sync_names = @($_sync_name)
    }

    $_working_dir = $( get_config_file_working_dir "${_config_file}" )

    $_sync_strategy=(get_config_file_sync_strategy ${_config_file})

    foreach ($_sync_name in $_sync_names) {
        if ($_sync_strategy -ne "native") {
            show_success_message "Cleaning docker-sync for sync name '${_sync_name}'" "3"
        }

        if (-not (Test-Path "${_working_dir}/${_sync_name}.log")) {
            New-Item -ItemType File -Path "${_working_dir}/${_sync_name}.log" -Force | Out-Null
        }

        if ($preferred_sync_env -eq "wsl") {
            $wsl_log_path = $( get_wsl_path "${_working_dir}/${_sync_name}.log" )
            wsl -d ${devbox_wsl_distro_name} bash --login -c "DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK=1 docker-sync clean --config='$( get_wsl_path ${_config_file} )' --sync-name='${_sync_name}' >> '${wsl_log_path}'"
        } elseif ($preferred_sync_env -eq "cygwin") {
            Start-Job -Name "sync_clean:${_sync_name}" {
                & "${Using:cygwin_dir}\bin\bash.exe" --login -c "DOCKER_SYNC_SKIP_DEPENDENCIES_CHECK=1 docker-sync clean --config='${Using:_config_file}' --sync-name='${Using:_sync_name}' >> '${Using:_working_dir}/${Using:_sync_name}.log'"
            } | Receive-Job -Wait
        }

        if (-not ($?)) {
            show_error_message "Unable to clean volumes syncs. See docker-sync output above. Process interrupted. Exit code: '$?'"
            show_error_message "Sync config file: ${_config_file}."
            Throw "Docker-sync clean error"
        }
    }
}

# start syncronization for volumes in all "docker-sync-*.yml" in directory
function docker_sync_start_all_directory_volumes($_configs_directory = "", $_show_logs = $true, $_with_health_check = $true) {
    if (-not ${_configs_directory} -or ! (Test-Path ${_configs_directory} -PathType Container)) {
        show_error_message "Unable to start sync docker volumes in directory '${_configs_directory}'. Working directory not found."
        exit 1
    }

    foreach ($_project_sync_file in (Get-ChildItem -Path ${_configs_directory} -Filter "docker-sync-*.yml" -Depth 1 | Select -ExpandProperty Name)) {
        docker_sync_start "${_configs_directory}/${_project_sync_file}" $null ${_show_logs} ${_with_health_check}
    }
}

# start syncronization for volumes in all "docker-sync-*.yml" in directory
function docker_sync_stop_all_directory_volumes($_configs_directory = "", $_kill_service_processes = $true) {
    if (-not ${_configs_directory} -or ! (Test-Path ${_configs_directory} -PathType Container)) {
        show_error_message "Unable to stop sync docker volumes in directory '${_configs_directory}'. Working directory not found."
        exit 1
    }

    foreach ($_project_sync_file in (Get-ChildItem -Path ${_configs_directory} -Filter "docker-sync-*.yml" -Depth 1 | Select -ExpandProperty Name)) {
        docker_sync_stop "${_configs_directory}/${_project_sync_file}" ${_kill_service_processes}
    }

    $_project_dir = (Split-Path -Path ${_configs_directory})
    kill_unison_orphan_processes ${_project_dir}
}

# cleanup after syncronization for volumes in all "docker-sync-*.yml" in directory
function docker_sync_clean_all_directory_volumes($_configs_directory = "") {
    if (-not ${_configs_directory} -or ! (Test-Path ${_configs_directory} -PathType Container)) {
        show_error_message "Unable to clean sync docker volumes in directory '${_configs_directory}'. Working directory not found."
        exit 1
    }

    foreach ($_project_sync_file in (Get-ChildItem -Path ${_configs_directory} -Filter "docker-sync-*.yml" -Depth 1 | Select -ExpandProperty Name)) {
        docker_sync_clean "${_configs_directory}/${_project_sync_file}"
    }
}

# get all syns names (equals to volume names) from the given config file
function get_config_file_sync_names($_config_file = "") {
    if (-not (Test-Path ${_config_file} -PathType Leaf)) {
        show_error_message "Unable to retrieve syncs name. File does not exist at path  '${_config_file}'."
        exit 1
    }

    $_syncs_content = (Get-Content -Path $_config_file | Select-String -Pattern "^syncs:" -Context 0, 100 | ForEach-Object { $_.Context.PostContext })

    $_sync_names = $_syncs_content | Select-String -Pattern "^\s{2,4}(\S+):" | ForEach-Object -MemberName Matches | ForEach-Object { $_.Groups[1].Value }

    return ${_sync_names}
}

# get working dir for syncs logs and pid-files
function get_config_file_working_dir($_config_file = "") {
    $_working_dir = ""

    if (-not ${_config_file}) {
        show_error_message "Unable to retrieve docker-sync config working dir."
        exit 1
    }

    $_working_dir = "$( Split-Path -Path ${_config_file} )/docker-sync"
    if (-not (Test-Path $_working_dir -PathType Container)) {
        New-Item -ItemType Directory -Path $_working_dir -Force | Out-Null
    }

    return ${_working_dir}
}

# get all syns names (equals to volume names) from the given config file
function get_directory_sync_names($_configs_directory = "") {
    if (-not (Test-Path ${_configs_directory} -PathType Container)) {
        show_error_message "Unable to collect directory syncs names. Dir does not exist at path  '${_configs_directory}'."
        exit 1
    }

    $_collected_sync_names = @()

    foreach ($_project_sync_file in (Get-ChildItem -Path ${_configs_directory} -Filter "docker-sync-*.yml" -Depth 1 | Select -ExpandProperty Name)) {
        $_config_sync_names = (get_config_file_sync_names "${_configs_directory}/${_project_sync_file}")
        foreach ($_sync_name in $_config_sync_names) {
            $_collected_sync_names += $_sync_name
        }
    }

    return [string]::Join(',', $_collected_sync_names)
}

# get all syns names (equals to volume names) from the given config file
function get_config_file_by_directory_and_sync_name($_configs_directory = "", $_sync_name = "") {
    if (-not (Test-Path ${_configs_directory} -PathType Container)) {
        show_error_message "Unable to find config by sync name. Dir does not exist at path  '${_configs_directory}'."
        exit 1
    }

    if (-not $_sync_name) {
        show_error_message "Unable to find config by sync name. Sync name cannot be empty. Given config dir: '${_configs_directory}'."
        exit 1
    }

    foreach ($_project_sync_file in (Get-ChildItem -Path ${_configs_directory} -Filter "docker-sync-*.yml" -Depth 1 | Select -ExpandProperty Name)) {
        $_config_sync_names = (get_config_file_sync_names "${_configs_directory}/${_project_sync_file}")
        if ( $_config_sync_names.Contains($_sync_name)) {
            return "${_configs_directory}/${_project_sync_file}"
        }
    }

    show_error_message "Unable to find config by sync name. Sync name '${_sync_name}' not found in directory '${_configs_directory}'."
}

############################ Public functions end ############################


############################ Local functions ############################

# open window with sync logs with runtime updating
function show_sync_logs_window($_config_file = "", $_sync_name = "") {
    if (-not ($_config_file) -or ! (Test-Path $_config_file -PathType Leaf)) {
        show_error_message "Unable to show logs window. Required parameters are missing: config file - '${_config_file}'"
        throw
    }

    $_working_dir = $( get_config_file_working_dir "${_config_file}" )
    if (-not $_sync_name) {
        $_sync_names = (get_config_file_sync_names "${_config_file}")
    } else {
        $_sync_names = @($_sync_name)
    }

    foreach ($_sync_name in $_sync_names) {
        if (-not (Test-Path "${_working_dir}/${_sync_name}.log")) {
            New-Item -ItemType File -Path "${_working_dir}/${_sync_name}.log" -Force | Out-Null
        }

        Start-Process PowerShell -ArgumentList "Get-Content '${_working_dir}/${_sync_name}.log' -tail 5 -wait"
    }
}

# close window with sync logs
function close_sync_logs_window($_config_file = "", $_sync_name = "") {
    if (-not ($_config_file) -or ! (Test-Path $_config_file -PathType Leaf)) {
        show_error_message "Unable to close logs window. Required parameters are missing: config file - '${_config_file}'"
        exit 1
    }

    if (-not $_sync_name) {
        $_sync_names = (get_config_file_sync_names "${_config_file}")
    } else {
        $_sync_names = @($_sync_name)
    }

    foreach ($_sync_name in $_sync_names) {
        $_regex_sync_logpath = $([regex]::Escape("${_sync_name}.log") )
        if (Get-WmiObject Win32_Process -Filter "name = 'powershell.exe' and commandLine like '%tail%' and commandLine like '%log%'" | Where-Object { $_.CommandLine -match $_regex_sync_logpath }) {
            Stop-Process ( Get-WmiObject Win32_Process -Filter "name = 'powershell.exe' and commandLine like '%tail%' and commandLine like '%log%'" |
                    Where-Object { $_.CommandLine -match $_regex_sync_logpath } |
                    Select -Expand ProcessId)
        }
    }
}

#start health-checker process which will restart sync in case daemon pid file dissappeared (sync daemon errored)
function start_background_health_checker($_config_file = "") {
    if (-not ($_config_file) -or ! (Test-Path $_config_file -PathType Leaf)) {
        show_error_message "Unable to start sync health-checker. Required config file is missing: config file - '${_config_file}'"
        exit 1
    }

    # Start process within the same tree, but after main shell execution is finished health-checker left running as a detached process
    # Processes called by [Start-Job] or [Invoke-Expression] are not detached processes and will be termnated together with the main programm
    Start-Process PowerShell -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass", "${devbox_root}/tools/docker/docker-sync-health-checker.ps1", "${_config_file}"
}

# kill health-checker process
function stop_background_health_checker($_config_file = "") {
    if (-not ($_config_file) -or ! (Test-Path $_config_file -PathType Leaf)) {
        show_error_message "Unable to start sync health-checker. Required config file is missing: config file - '${_config_file}'"
        exit 1
    }

    if (Get-WmiObject Win32_Process -Filter "name = 'powershell.exe' and commandLine like '%docker-sync-health-checker[.]ps1%'" | Where-Object { $_.CommandLine -match "$([regex]::Escape($_config_file) )" }) {
        Stop-Process (Get-WmiObject Win32_Process -Filter "name = 'powershell.exe' and commandLine like '%docker-sync-health-checker[.]ps1%'" |
                Where-Object { $_.CommandLine -match "$([regex]::Escape($_config_file) )" } |
                Select -Expand ProcessId)
    }
}

function kill_unison_orphan_processes($_project_dir = "") {
    if (-not ($_project_dir) -or ! (Test-Path $_project_dir -PathType Container)) {
        show_error_message "Unable to kill unison orphan processes. Required project dir is missing at path - '${_project_dir}'"
        exit 1
    }

    # simulate unix slashes to find process properly
    $_project_dir = ($_project_dir -replace '\\', '/')
    if (Get-WmiObject Win32_Process -Filter "name = 'unison.exe'" | Where-Object { $_.CommandLine -match "$([regex]::Escape($_project_dir) )" }) {
        Stop-Process (Get-WmiObject Win32_Process -Filter "name = 'unison.exe'" |
                Where-Object { $_.CommandLine -match "$([regex]::Escape($_project_dir) )" } |
                Select -Expand ProcessId)
    }
}

function get_config_file_option($_config_file = "", $_option_name = "") {
    if (-not ${_config_file}) {
        show_error_message "Unable to retrieve sync option. File does not exist at path  '${_config_file}'."
        exit
    }

    if (-not ${_config_file}) {
        show_error_message "Unable to retrieve sync option. Option name cannot be empty"
        exit
    }

    $_option_match = (Get-Content -Raw -Path ${_config_file} | Select-String "options:[\S\s]+?\s{2,6}(${_option_name}\ ?:\ ?.+?)\s+?[\S\s]+?syncs:" -List | ForEach-Object -MemberName Matches | ForEach-Object { $_.Groups[1].Value })

    if ($_option_match) {
        $_option_value = $_option_match.Split(':')[1]
    } else {
        $_option_value = ''
    }

    return ${_option_value}
}

function get_config_file_sync_strategy($_config_file = "") {

    if (-not ${_config_file}) {
        show_error_message "Unable to retrieve sync option. File does not exist at path  '${_config_file}'."
        exit
    }

    $_syncs_content = (Get-Content -Path $_config_file | Select-String -Pattern "^syncs:" -Context 0, 20 | ForEach-Object { $_.Context.PostContext })

#    $_sync_strategy = $_syncs_content | Select-String -Pattern "^\s{2,4}(\S+):" | ForEach-Object -MemberName Matches | ForEach-Object { $_.Groups[1].Value }
    $_sync_strategy_match = $_syncs_content | Select-String -Pattern "^\s{4,8}sync_strategy:\s?(\S+)" | ForEach-Object -MemberName Matches | ForEach-Object { $_.Groups[1].Value } | Select -First 1

    if ($_sync_strategy_match) {
        $_sync_strategy = ($_sync_strategy_match -Replace "'| ")
    } else {
        $_sync_strategy = ""
    }

    echo "${_sync_strategy}"
}

############################ Local functions end ############################

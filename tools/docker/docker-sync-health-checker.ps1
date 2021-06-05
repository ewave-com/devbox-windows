Set-PSDebug -strict;

$docker_sync_file = $args[0]

$devbox_root = $((Split-Path -Parent $MyInvocation.MyCommand.Path) | Split-Path -Parent | Split-Path -Parent)

if (-not ${devbox_root} -or ! (Test-Path $devbox_root -PathType Container) -or ! (${docker_sync_file}) -or ! (Test-Path $docker_sync_file -PathType Leaf)) {
    echo "Unable to initialize docker-sync-health-checker. Exit."
    exit;
}

. "${devbox_root}/tools/system/require-once.ps1"
. require_once "${devbox_root}/tools/docker/docker-sync.ps1"

$watched_sync_names = (get_config_file_sync_names "${docker_sync_file}")
$working_dir = (get_config_file_working_dir "${docker_sync_file}")
$max_attempts = 10
$attempt_no = 0

$global:hanging_unison_hashes=@()
$process_name = 'unison%'
$cpu_percentage_threshold = '95' # cpu percentage per logical core as unison if single-thread process
$max_cycles_before_kill = 3;

function start_watch() {
    $restart_required = $false
    while (${attempt_no} -le ${max_attempts}) {

        if(is_main_healthchecker_process) {
            handle_hanging_unison_proceses
        }

        foreach ($sync_name in ${watched_sync_names}) {
            # Clear log file once its size became over 10MB
            if ((Get-Item "${working_dir}/${sync_name}.log").length/10MB -gt 1) {
                try {
                    Clear-Content -Path "${working_dir}/${sync_name}.log" -Force | Out-Null
                } catch { }
            }

            if (-not (Test-Path "${working_dir}/${sync_name}.pid" -PathType Leaf)) {

                $restart_required = $true

                if (-not (Test-Path "${working_dir}/${sync_name}.log" -PathType Leaf)) {
                    New-Item -ItemType File -Path "${_working_dir}/${_sync_name}.log" -Force | Out-Null
                }
                Add-Content -Path "${working_dir}/${sync_name}.log" -Value "[$( Get-Date )] ### An error occurred during syncing files. Trying to restart docker-sync process (attempt #${attempt_no}). Please wait a few second. ###"

                break;
            }
        }

        if ($restart_required) {
            $attempt_no = ($attempt_no + 1)

            try {
                $stop_output = ""
                # stop operation will terminate all syncs from the config ignoring sync_name option
                # https://github.com/EugenMayer/docker-sync/blob/0.5.14/lib/docker-sync/sync_manager.rb#L144
                # So we need to stop all config syncs and stert each separately
                $stop_output = (docker_sync_stop "${docker_sync_file}" $false)
                $stop_output | Add-Content -Path "${working_dir}/${sync_name}.log"

                foreach ($sync_name in ${watched_sync_names}) {
                    try {
                        $output = ""

                        # split operation and log writing to avoid busy file handler error
                        $output = (docker_sync_start "${docker_sync_file}" ${sync_name} $false $false)
                        $output | Add-Content -Path "${working_dir}/${sync_name}.log"
                        $output = ""
                    } catch {
                        if ($output) {
                            $output | Add-Content -Path "${working_dir}/${sync_name}.log"
                            $output = ""
                        }
                        Add-Content -Path "${working_dir}/${sync_name}.log" -Value $Error[0]
                        Add-Content -Path "${working_dir}/${sync_name}.log" -Value "[$( Get-Date )] ### An error occured by restarting sync process for sync '${sync_name}'. ###"
                    }
                }

                Add-Content -Path "${working_dir}/${sync_name}.log" -Value "[$( Get-Date )] ### Sync recovery successfully finished. ###"

                $restart_required = $false
            } catch {
                if ($stop_output) { $stop_output | Add-Content -Path "${working_dir}/${sync_name}.log" }
                if ($output) { $output | Add-Content -Path "${working_dir}/${sync_name}.log" }
                Add-Content -Path "${working_dir}/${sync_name}.log" -Value $Error[0]
                Add-Content -Path "${working_dir}/${sync_name}.log" -Value "[$( Get-Date )] ### An error occured by restarting sync process. ###"
            }
        } else {
            $attempt_no = 0
        }

        Start-Sleep -Seconds 10
    }

    Add-Content -Path "[$( Get-Date )] ${working_dir}/${sync_name}.log" -Value "[$( Get-Date )] ### Docker-sync restarting failed after ${attempt_no} attempts. ###"
    Add-Content -Path "[$( Get-Date )] ${working_dir}/${sync_name}.log" -Value "[$( Get-Date )] ### This case should be investigated. Please contact DevBox guys. ###"
}

function is_main_healthchecker_process() {
    $_first_process_pid = (Get-WmiObject Win32_Process -Filter "name = 'powershell.exe' and commandLine like '%docker-sync-health-checker[.]ps1%'" | Sort-Object -Property ProcessId | Select -First 1 -Expand ProcessId)
    if ($_first_process_pid -eq $PID) {
        return $true
    }

    return $false
}

function handle_hanging_unison_proceses() {
    $_cycle_possible_hanging_unison_pids=(Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process -filter "PercentProcessorTime >= ${cpu_percentage_threshold} and Name like '${process_name}%'" | Select -Expand IDProcess)
    if(!$_cycle_possible_hanging_unison_pids) {
        if($global:hanging_unison_hashes) {
            show_success_message "No process found with high CPU utilization, clear unison reset list"
            $global:hanging_unison_hashes=@();
        }
        return;
    }

    $_cycle_possible_hanging_unison_hashes = @()
    foreach ($_unison_pid in $_cycle_possible_hanging_unison_pids) {
        # there is no proper way to detect process is actually hanging
        # so we calculate average cpu usage during 3 seconds
        # this is required to provide more accurate value and reduce influence of instantaneous values
        # in case avg cpu usage greater than ${cpu_percentage_threshold} value after ${max_cycles_before_kill} - we kill such process as hanging, further health-checked logic will restart it from scratch

        $_reset_candidate_confirmed = $true
        $_metric_counter = 0
        $_metric_command = "Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process -filter 'IDProcess = ${_unison_pid}' | Select -First 1 -Expand PercentProcessorTime"
        while ($_metric_counter -lt 3) {
            $_pid_cpu_percentage = (Invoke-Expression $_metric_command)
            show_warning_message "PID '${_unison_pid}', CPU usage ${_metric_counter} '${_pid_cpu_percentage}'"
            if ($_pid_cpu_percentage -lt ${cpu_percentage_threshold}) {
                $_reset_candidate_confirmed = $false
                break;
            }
            $_metric_counter++
            Start-Sleep 1
        }

        if($_reset_candidate_confirmed) {
            show_warning_message "Unison reset candidate: PID '${_unison_pid}'"

            $_existing_hash = $null
            foreach($_hash in $global:hanging_unison_hashes) {
                if ($_hash | Select-String -Pattern "^${_unison_pid}:") {
                    $_existing_hash = $_hash
                    break
                }
            }

            if ($_existing_hash) {
                $_cycle_num = (([int]$_existing_hash.Split(':')[1]) + 1)
                if ($_cycle_num -lt $max_cycles_before_kill) {
                    $_cycle_possible_hanging_unison_hashes += "${_unison_pid}:${_cycle_num}"
                } else {
                    if (Get-WmiObject Win32_Process -Filter "ProcessId = ${_unison_pid}") {
                        show_warning_message "[$( Get-Date )] ### Killing PID '${_unison_pid}' as its CPU over the threshold '${cpu_percentage_threshold}' for '${max_cycles_before_kill}' cycles"
                        # remove killed pid from the candidate list
                        $global:hanging_unison_hashes = $global:hanging_unison_hashes | Where-Object {$_ -notmatch "^${_unison_pid}:" }
                        Stop-Process ${_unison_pid}
                    }
                }
            } else {
                $_cycle_possible_hanging_unison_hashes += "${_unison_pid}:1"
            }
        } else {
            show_success_message "[$( Get-Date )] ### CPU utilization normalized for PID '${_unison_pid}', reset not required"
            # remove normalized pid from the candidate list
            $global:hanging_unison_hashes = $global:hanging_unison_hashes | Where-Object {$_ -notmatch "^${_unison_pid}:" }
        }
    }

    $global:hanging_unison_hashes = $_cycle_possible_hanging_unison_hashes
}

start_watch

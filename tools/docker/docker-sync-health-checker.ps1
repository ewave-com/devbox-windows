$devbox_root = $args[0]
$docker_sync_file = $args[1]
Set-PSDebug -strict;

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

$restart_required = $false
while (${attempt_no} -le ${max_attempts}) {
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

Add-Content -Path "${working_dir}/${sync_name}.log" -Value "[$( Get-Date )] ### Docker-sync restarting failed after ${attempt_no} attempts. ###"
Add-Content -Path "${working_dir}/${sync_name}.log" -Value "[$( Get-Date )] ### This case should be investigated. Please contact DevBox guys. ###"

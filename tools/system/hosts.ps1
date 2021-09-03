. require_once "${devbox_root}/tools/system/output.ps1"

############################ Public functions ############################

# $_domains - comma-separated list
function add_website_domain_to_hosts($_domains = "", $_ip_address = "127.0.0.1") {
    if ($_domains -eq "") {
        show_error_message "Unable to add website to hosts file. Website domain cannot be empty"
        exit 1
    }

    $_hosts_filepath = "$env:windir/System32/drivers/etc/hosts"
    $_domainsArr = $_domains.Split(",")
    $_all_domain_lines = @()
    foreach ($_domain in $_domainsArr) {
        $_regex_hosts_record = [regex]::Escape("${_ip_address} ${_domain}")
        if (-not (Select-String -Path $_hosts_filepath -Pattern "^${_regex_hosts_record}$")) {
            $_all_domain_lines += "${_ip_address} ${_domain}"
        }
    }

    if ($_all_domain_lines) {
        $_all_domain_lines = "$([string]::Join("`n", $_all_domain_lines) )"
        try {
            Start-Process PowerShell -Wait -Verb RunAs -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass", "Add-Content -Encoding UTF8 -Path '${_hosts_filepath}' -Value '${_all_domain_lines}'"
        } catch {
            # catch errors if user missed UAC window and process failed due to timeout
            show_error_message "Unable to add domains to the hosts file due to the exception: $($_.Exception)"
            exit 1
        }
    }
}

# $_domains - comma-separated list
function delete_website_domain_from_hosts($_domains = "", $_ip_address = "127.0.0.1") {
    if ($_domains -eq "") {
        show_error_message "Unable to remove website from hosts file. Website domain cannot be empty"
        Exit 1
    }

    $_hosts_filepath = "$env:windir/System32/drivers/etc/hosts"
    $_domainsArr = $_domains.Split(",")
    $_all_hosts_regex = @()
    foreach ($_domain in $_domainsArr) {
        $_regex_hosts_record = [regex]::Escape("${_ip_address} ${_domain}")
        if (Select-String -Path $_hosts_filepath -Pattern "${_regex_hosts_record}") {
            $_all_hosts_regex += "$_regex_hosts_record"
        }
    }

    if ($_all_hosts_regex) {
        $_all_hosts_regex = "^($([string]::Join(')|(', $_all_hosts_regex)))$"

        $hostsScriptBlock = {
            function rm_host_by_regex($regex) {
                # read and write without pipe, otherwise writing in-place will be impossible because of busy file descriptor
                $content = (Get-Content -Path "$env:windir/System32/drivers/etc/hosts" | Where-Object { $_ -notmatch $regex })
                if ($content) {
                    $content | Set-Content -Path "$env:windir/System32/drivers/etc/hosts"
                }
            }
        }

        # run priveleged function instead of pipe calls because of 'Start-Process' parsing limitations
        try {
            $content = (Get-Content -Path "$env:windir/System32/drivers/etc/hosts" | Where-Object { $_ -notmatch $_all_hosts_regex })
            # additionally check to avoid file emptying due to regex error
            if ($content) {
                Start-Process PowerShell -Wait -Verb RunAs -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass", "-Command & {$hostsScriptBlock rm_host_by_regex('${_all_hosts_regex}')}"
            }
        } catch {
            # catch errors if user missed UAC window and process failed due to timeout
            show_error_message "Unable to add domains to the hosts file due to the exception: $($_.Exception)"
            exit 1
        }
    }
}

############################ Public functions end ############################

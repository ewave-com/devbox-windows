if (-not (Get-Variable 'imported_scripts' -Scope 'Global' -ErrorAction 'Ignore')) {
    $imported_scripts = @()
}

############################ Public functions ############################

function require_once($_included_path = "") {
    if ($_included_path -eq "") {
        throw "Unable to include source. Included path cannot be empty"
    }

    if (-not (Test-Path ${_included_path} -PathType Leaf) -and (Test-Path "${devbox_root}/${_included_path}" -PathType Leaf)) {
        $_included_path = "${devbox_root}/${_included_path}"
    }

    if (-not (Test-Path "${_included_path}" -PathType Leaf)) {
        throw "Unable to include source. Included file does not exist at path '${_included_path}'"
    }

    if ( $imported_scripts.Contains($_included_path)) {
        return
    }

    # Commented out as Get-Command is too slow and called many times
    #     the following function and variable checks needed for cases script was imported before without require_once
    #    $_first_func = (Select-String -Path $_included_path -Pattern '^function ([A-Za-z0-9_\-]+)[ ]?\(.*$' -List | ForEach-Object -MemberName Matches | ForEach-Object { $_.Groups[1].Value })
    #    if ($_first_func -and (Get-Command $_first_func -ErrorAction SilentlyContinue)) {
    #        $imported_scripts += $_included_path
    #        return
    #    }

    $imported_scripts += $_included_path
    . ${_included_path}
}

############################ Public functions end ############################

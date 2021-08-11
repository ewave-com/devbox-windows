#!/usr/bin/env bash

require_once "$devbox_root/tools/system/constants.ps1"

############################ Public functions ############################

function show_error_message($_message = "", $_hierarchy_lvl = "0") {
    $_prefix = (get_hierarchy_lvl_prefix ${_hierarchy_lvl})
    Write-Host -ForegroundColor $RED "${_message}"
}

function show_warning_message($_message = "", $_hierarchy_lvl = "0") {
    $_prefix = (get_hierarchy_lvl_prefix ${_hierarchy_lvl})
    Write-Host -ForegroundColor $YELLOW "${_prefix}${_message}"
}

function show_success_message($_message = "", $_hierarchy_lvl = "0") {
    $_prefix = (get_hierarchy_lvl_prefix ${_hierarchy_lvl})
    Write-Host -NoNewline "$( Get-Date -UFormat '%d %b %X' ) "
    Write-Host -ForegroundColor $GREEN "${_prefix}${_message}"
}

function show_message($_message = "", $_hierarchy_lvl = "0") {
    $_prefix = (get_hierarchy_lvl_prefix ${_hierarchy_lvl})
    Write-Host "${_prefix}${_message}"
}

function show_info_value_message($_message = "", $_value = "") {
    Write-Host -ForegroundColor $GREEN -NoNewline "${_message}: "
    Write-Host "${_value}"
}

function print_section_header($_header = "") {
    print_filled_line "" 80 "="
    print_filled_line "${_header}" 80 ' '
    print_filled_line "" 80 "="
}

function print_section_footer() {
    print_filled_line "" 80 "="
}


############################ Public functions end ############################

############################ Local functions ############################

function print_filled_line($_string = "", $_total_length = 80, $_filler_char = "=") {
    # ${#string} expands to the length of $string
    $_string_length = $_string.Length

    if (-not $_string_length -eq 0) {
        $_filler_length = $( (($_total_length - $_string_length - 2) / 2) )
        $_filler = ''.PadLeft($_filler_length, $_filler_char)
        # add extra filler to align header and footer for strings with odd length
        if (($_string_length % 2) -eq 0) { $_extra_filler = "" } else { $_extra_filler = $_filler_char }

        Write-Host -NoNewline $_filler
        Write-Host -ForegroundColor $GREEN -NoNewline " ${_string} "
        Write-Host $_filler
    } else {
        $_filler = ''.PadLeft($_total_length, $_filler_char)
        Write-Host $_filler
    }
}

function get_hierarchy_lvl_prefix($_level = "0") {
    if ("${_level}" -eq "0") {
        return ""
    }

    $_prefix = ""
    Switch -exact (${_level}) {
        "1" { $_prefix = " > "; break }
        "2" { $_prefix = "    * "; break }
        "3" { $_prefix = "      * "; break }
        default { $_prefix = ""; }
    }

    return $_prefix
}

############################ Local functions end ############################

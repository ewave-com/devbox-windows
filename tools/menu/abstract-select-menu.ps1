. require_once "${devbox_root}/tools/system/output.ps1"
#Source: http://mspowershell.blogspot.com/2009/02/cli-menu-in-powershell.html?m=1

############################ Public functions ############################

function select_menu_item($_options_string, $_options_delimiter = ",") {
    if (-not ${_options_string}) {
        show_error_message "Unable to draw menu. Initial items not given."
        exit 1
    }

    $_options = $_options_string.Split($_options_delimiter)

    $cursor = 0

    function draw_menu($_options, $cursor) {
        for ($i = 0; $i -le ($_options.Length - 1); $i++) {
            if ($i -eq $cursor) {
                Write-Host " > [$i] $( $_options[$i] )" -ForegroundColor Green
            } else {
                Write-Host "   [$i] $( $_options[$i] )"
            }
        }
    }

    function clear_menu($_options) {
        $_current_line = $Host.UI.RawUI.CursorPosition.Y
        $_console_width = $Host.UI.RawUI.BufferSize.Width

        for ($i = 0; $i -le ($_options.Length - 1); $i++) {
            [Console]::SetCursorPosition(0, ($_current_line - $i))
            [Console]::Write("{0,-$_console_width}" -f " ")
        }

        [Console]::SetCursorPosition(0, ($_current_line - $_options.Length))
    }

    draw_menu $_options $cursor

    while ($press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")) {
        $keycode = $press.VirtualKeyCode
        $keychar = $press.Character

        # Check for enter/space (13 - enter, 32 - space)
        if ("${keycode}" -eq 13 -or "${keycode}" -eq 32) { break; }
        # Allow typing numeric index of selection
        if (${keychar} -match '^[0-9]+$') {
            if ($cursor -ne 0 -and $_options["$cursor$keychar"]) {
                $cursor = [int]"${cursor}${keychar}"
            } elseif($_options["$keychar"]) {
                $cursor = [int]"${keychar}"
            }
        }

        # cursor up, left: previous item
        if ($keychar -eq 'w' -or $keychar -eq 'a' -or $keycode -eq 38 -or $keycode -eq 37) { if ($cursor -gt 0) { $cursor-- } else { $cursor = ($_options.Length - 1) } }
        # cursor down, right: next item
        if ($keychar -eq 's' -or $keychar -eq 'd' -or $keycode -eq 40 -or $keycode -eq 39) { if ($cursor -lt ($_options.Length - 1)) { $cursor++ } else { $cursor = 0 } }
        # Home, PgUp keys: first item
        if ($keycode -eq 36 -or $keycode -eq 33) { $cursor = 0 }
        # End, PgDown keys: last item
        if ($keycode -eq 35 -or $keycode -eq 34) { $cursor = ($_options.Length - 1) }
        # q, carriage return: quit
        if ($keychar -eq 'q' -or $keycode -eq 27) { Write-Host "Exit"; Exit 0 }

        # Redraw menu
        clear_menu $_options
        draw_menu $_options $cursor
    }

    return $_options[$cursor]
}

function draw_menu_header($_header_text) {
    print_filled_line "" 50 "-"
    print_filled_line ${_header_text} 50 " "
    print_filled_line "" 50 "-"
}

function draw_menu_footer($_header_text) {
    print_filled_line "" 50 "-"
    show_message ""
}

############################ Public functions end ############################

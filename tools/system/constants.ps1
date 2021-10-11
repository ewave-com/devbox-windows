$devbox_infra_dir = "$devbox_root/configs/infrastructure"
$devbox_projects_dir = "$devbox_root/projects"
$dotenv_defaults_filepath = "${devbox_root}/configs/project-defaults.env"
$dotenv_infra_filepath = "${devbox_root}/configs/infrastructure/infra.env"
# global variable to set active env filepath which is in use currently
$current_env_filepath = ""

$host_user = $env:UserName

$docker_compose_log_level = "ERROR"

# update devbox vendor packages automatically (monthly)
$composer_autoupdate = $true

# update stored docker images with ':latest' tag automatically (monthly)
$docker_images_autoupdate = $true
# coma-separated list on skipped images to be refreshed automatically (e.g. from private storages)
$docker_images_autoupdate_skip_images=""


# wsl is more stable and shows better perfomance of inode watching, but a bit slower in initial filesystem scanning (wsl fstat system calls - unix simulation)
# cygwin is a bit faster in initial filesystem scanning (native WinOs fstat calls), but a bit slower in changes watching, besides might have some unexpected errors
# in general both options work well, wsl is recommended option, cygwin is added as alternative in case wsl is not available in your OS.
# possible value either "cygwin" or "wsl"
#$preferred_sync_env = "wsl"
$preferred_sync_env = "cygwin"

$cygwin_dir = "$( (Get-WmiObject Win32_OperatingSystem).SystemDrive )/cygwin64"
$cygwin_home_dirname = ("$env:UserName" -Replace '\s', '_')

$devbox_wsl_distro_name = "devbox-distro"
$wsl_distro_dir = "$env:ALLUSERSPROFILE/wsl/${devbox_wsl_distro_name}"

$os_type = "windows"

function get_arch_type() {
    $_proc_info = $env:PROCESSOR_ARCHITECTURE

    if ( $_proc_info -eq "AMD64") {
        $_cpu_arch = "x64"
    } elseif ($_proc_info -eq "X86") {
        $_cpu_arch = "x32"
    } elseif ($_proc_info -eq "ARM64") {
        $_cpu_arch = "arm64"
    } else {
        $_cpu_arch = "unknown"
    }

    return $_cpu_arch
}

$arch_type = (get_arch_type)

##################################################################################

# Set color variable
$RED = 'Red'
$GREEN = 'Green'
$YELLOW = 'Yellow'
$BLUE = 'Blue'
$WHITE = 'White'
$SET = 'White'

# if you need to override any parameters from this file, just create the file "${devbox_root}/constants-override.sh" and put required params there
# variables will be overloaded
if (Test-Path "${devbox_root}/constants-override.ps1" -PathType Leaf) {
  . require_one "${devbox_root}/constants-override.ps1"
}

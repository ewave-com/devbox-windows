$devbox_infra_dir = "$devbox_root/configs/infrastructure"
$devbox_projects_dir = "$devbox_root/projects"
$dotenv_defaults_filepath = "${devbox_root}/configs/project-defaults.env"
$dotenv_infra_filepath = "${devbox_root}/configs/infrastructure/infra.env"
# global variable to set active env filepath which is in use currently
$current_env_filepath = ""

$host_user = $env:UserName

$docker_compose_log_level = "ERROR"

$os_type = "windows"

# wsl is more stable and shows better perfomance of inode watching, but a bit slower in initial filesystem scanning (wsl fstat system calls - unix simulation)
# cygwin is a bit faster in initial filesystem scanning (native WinOs fstat calls), but a bit slower in changes watching, besides might have some unexpected errors
# in general both options work well, wsl is recommended option, cygwin is added as alternative in case wsl is not available in your OS.
# possible value either "cygwin" or "wsl"
#$preferred_sync_env = "wsl"
$preferred_sync_env = "cygwin"

$cygwin_dir = "$( (Get-WmiObject Win32_OperatingSystem).SystemDrive )/cygwin64"

$devbox_wsl_distro_name = "devbox-distro"
$wsl_distro_dir = "$env:ALLUSERSPROFILE/wsl/${devbox_wsl_distro_name}"

# Set color variable
$RED = 'Red'
$GREEN = 'Green'
$YELLOW = 'Yellow'
$BLUE = 'Blue'
$WHITE = 'White'
$SET = 'White'
. require_once "$devbox_root/tools/system/constants.ps1"
. require_once "$devbox_root/tools/system/output.ps1"
. require_once "$devbox_root/tools/system/wsl.ps1"

############################ Public functions ############################

$env:devbox_env_path_updated = $false

function install_dependencies() {
    install_chocolatey
    install_docker

    if ($preferred_sync_env -eq "wsl" -and (is_wsl_available)) {
        install_wsl
        install_wsl_docker_sync
        install_wsl_unison
    } else {
        install_cygwin
        install_cygwin_docker_sync
        install_cygwin_unison
    }
    install_composer
    install_extra_packages
    register_devbox_scripts_globally

    if ($env:devbox_env_path_updated -eq $true) {
        show_success_message "Installed packages updated your PATH system variable."
        show_warning_message "!!! To apply changes please close this window and start again usin new console window !!!."
        $env:devbox_env_path_updated = $null
        exit
    }
    $env:devbox_env_path_updated = $null
}

############################ Public functions end ############################

############################ Local functions ############################

function install_chocolatey() {
    if (-not $env:ChocolateyInstall -or -not (Test-Path "$env:ChocolateyInstall/bin/choco.exe")) {
        show_success_message "Installing Chocolatey package manager."
        Start-Process PowerShell -Wait -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass", "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"

        add_directory_to_env_path "$env:ALLUSERSPROFILE\chocolatey\bin"

        $env:devbox_env_path_updated = $true
    }
}

# Check and install docker if missing
function install_docker() {
    try {
        $_is_docker_installed = ((Test-Path "$Env:ProgramFiles\Docker\Docker\resources\docker.exe") -or (docker version))
    } catch {
        $_is_docker_installed = $false
    }

    try {
        # "docker-compose version" is simplier, but takes ~1 second to just get version, so read version from simple json file is much faster
        if (Test-Path ${Env:ProgramFiles}\Docker\Docker\resources\componentsVersion.json) {
            $_compose_version = (Get-Content ${Env:ProgramFiles}\Docker\Docker\resources\componentsVersion.json | Out-String | ConvertFrom-Json).ComposeVersion
        } elseif(Test-Path "${Env:ProgramFiles}\Docker\Docker\resources\bin\docker-compose.exe") {
            $_compose_version = (& "${Env:ProgramFiles}\Docker\Docker\resources\bin\docker-compose.exe" version --short)
        } else {
            $_compose_version = "0"
        }
    }
    catch {
        $_compose_version = "0"
    }

    $autoreistall_docker_confirmed = $false
    $_compose_min_version = "1.25.0"
    if (${_is_docker_installed} -and $_compose_version -lt $_compose_min_version) {
        show_warning_message "You are running docker-compose version '$_compose_version'. DevBox requires version '$_compose_min_version' or higher."
        show_warning_message "Docker and docker-compose will be tried to be updated automatically or you can reinstall Docker manually. This is one-time operation."
        $reply = Read-Host -Prompt "Update Docker automatically?[y/n]"
        if ($reply -notmatch "[yY]") {
            show_warning_message "You selected manual Docker installation. Exited"
            Exit 1
        }

        $autoreistall_docker_confirmed = $true

        if (Test-Path "$Env:ProgramFiles\Docker\Docker\Docker for windows Installer.exe" -PathType Leaf) {
            Start-Process -Wait -FilePath "$Env:ProgramFiles\Docker\Docker\Docker for windows Installer.exe" -ArgumentList "uninstall", "--quiet"
            show_success_message "Docker was successfully uninstalled."
            $_is_docker_installed = $false
        } elseif (Test-Path "$Env:ProgramFiles\Docker\Docker\Docker Desktop Installer.exe" -PathType Leaf) {
            Start-Process -Wait -FilePath "$Env:ProgramFiles\Docker\Docker\Docker Desktop Installer.exe" -ArgumentList "uninstall", "--quiet"
            show_success_message "Docker was successfully uninstalled."
            $_is_docker_installed = $false
        } else {
            show_error_message "Unable to find current Docker location to uninstall previous version. Please reinstall Docker manually and try to start devbox again."
            exit
        }
    }

    if ($_is_docker_installed -eq $false) {
        if (! $autoreistall_docker_confirmed) {
            $reply = Read-Host -Prompt "Docker is not detected on your computer. Install Docker automatically?[y/n]"
            show_warning_message "Please disable the setting 'Use the WSL 2 based engine' in General Docker Settings after installation finished and in case of problems with docker starting because of WSL 2."
            if ($reply -notmatch "[yY]") {
                show_warning_message "You selected manual Docker installation. Install it and try to start devbox again. Exited"
                Exit 1
            }
        }

        if (-not (Test-Path "$download_dir/Docker_Desktop_Installer.exe" -PathType Leaf)) {
            $download_dir = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
            show_success_message "Downloading new Docker version into $download_dir. Please wait a few minutes"
            (new-object System.Net.WebClient).DownloadFile("https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe", "${download_dir}/Docker_Desktop_Installer.exe")
        }

        Start-Process -Wait -FilePath "$download_dir/Docker_Desktop_Installer.exe" -ArgumentList "install --quiet"
    }

    if (-not (Get-Process 'com.docker.proxy' -ErrorAction Ignore)) {
        $_docker_started = $false
        show_warning_message "Docker is installed but not running. Trying to start docker. DevBox continue working after Docker started."
        if (Test-Path "$Env:ProgramFiles\Docker\Docker\Docker for Windows.exe" -PathType Leaf) {
            Start-Process -FilePath "$Env:ProgramFiles\Docker\Docker\Docker for Windows.exe"
            $_docker_started = $true
        } elseif (Test-Path "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe" -PathType Leaf) {
            Start-Process -FilePath "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
            $_docker_started = $true
        } else {
            show_error_message "Unable to find current Docker location to start. Please run Docker manually and try to start devbox again."
            Exit 1
        }

        $_docker_running = $false
        $_attempts = 0
        While ($_docker_running -ne $true) {
            $server_output = ''
            try {
                $server_output = (docker version --format '{{.Server.Version}}')
            } catch { }

            if (($server_output | Select-String "docker daemon is not running") -or ! (Get-Process 'com.docker.proxy' -ErrorAction Ignore)) {
                $_attempts += 1
                Start-Sleep 1
            } else {
                $_docker_running = $true
            }
            if ($_attempts -ge 30) {
                show_error_message "Docker is still not running after 30 seconds. It might be possibly corrupted or just slow. You can start docker manually or increase a timeout"
                exit 1
            }
        }
    }

    if (-not (Get-Process 'com.docker.proxy' -ErrorAction Ignore)) {
        show_error_message "Unable to start Docker. Please run docker manually and start devbox again."
        Exit 1
    }
}

function is_wsl_available() {
    $wsl_available = $false
    try {
        Get-Command wsl | Out-Null
        if ($?) {
            $wsl_available = $true
        }
    } catch {
        $wsl_available = $false
    }

    return $wsl_available
}

function install_wsl() {
    $wsl_devbox_distro_installed = $false
    try {
        wsl -d "${devbox_wsl_distro_name}" echo | Out-Null
        if ($?) {
            $wsl_devbox_distro_installed = $true
        }
    } catch {
        $wsl_devbox_distro_installed = $false
    }

    if (-not $wsl_devbox_distro_installed) {
        # a bit tricky but Start-Process doesn't return any output, throw an error if feature disabled to get status by exit code
        $check_proc = Start-Process PowerShell -Wait -WindowStyle Hidden -Verb RunAs -Passthru -ArgumentList "-ExecutionPolicy Bypass", "if (((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State) -ne 'Enabled') { throw } "
        if ($check_proc.ExitCode -ne '0') {
            show_success_message "Enabling WSL Feature"
            Start-Process PowerShell -Wait -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass", "Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Microsoft-Windows-Subsystem-Linux -LogLevel Errors"
            show_warning_message "Please restart your computer to apply enabled 'Windows Subsysten for Linux' (WSL) Feature."
            exit;
        }

        show_success_message "Installing WSL distribution for DevBox"
        $download_dir = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

        if (-not (Test-Path "$download_dir/wsl-Ubuntu-16.04.zip")) {
            # install 16.04 as more lightwight distro (appx size ~200Mb), for comparison 20.04 distro appx takes ~440 MB
            Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1604 -OutFile "$download_dir/wsl-Ubuntu-16.04.zip" -UseBasicParsing
        }

        Expand-Archive "$download_dir/wsl-Ubuntu-16.04.zip" "$download_dir/wsl-Ubuntu-16.04/" -Force

        New-Item -Type Directory "$wsl_distro_dir/" -Force | Out-Null
        wsl --import $devbox_wsl_distro_name "$wsl_distro_dir/" "$download_dir/wsl-Ubuntu-16.04/install.tar.gz"
        wsl --set-version $devbox_wsl_distro_name 1

        $wsl_conf_path = "$wsl_distro_dir/rootfs/etc/wsl.conf"
        if (-not (Test-Path $wsl_conf_path)) {
            #https://stackoverflow.com/questions/51336147/how-to-remove-the-win10s-path-from-wsl
            New-Item -Type File $wsl_conf_path -Force
            Add-Content -Path $wsl_conf_path -Value ""
            Add-Content -Path $wsl_conf_path -Value "[interop]"
            Add-Content -Path $wsl_conf_path -Value 'appendWindowsPath=false # append Windows path to $PATH variable; default is true'
            wsl -d $devbox_wsl_distro_name chmod 644 /etc/wsl.conf

            #             set bitmask Flags 5 instead of 7 to deny wsl load windows PATH, # admin perms not needed for some reason
            Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | Where-Object { (Get-ItemProperty "Registry::$_" -Name DistributionName).DistributionName -eq "devbox-distro" } | ForEach-Object { Set-ItemProperty "Registry::$_" -Name Flags -Value 5 }
        }

        show_success_message "Installing required software into WSL Distribution"
        wsl -d $devbox_wsl_distro_name apt update | Out-Null
        wsl -d $devbox_wsl_distro_name apt install -y openssl ruby ruby-dev rubygems | Out-Null
    }
}

function install_wsl_docker_sync() {
    # docker daemon is running on host system, not required inside wsl, map only docker client bin
    # docker dompose is not required inside wsl as well

    if (-not (Test-Path "$wsl_distro_dir/rootfs/usr/local/bin/docker")) {
        $wsl_path_docker = (get_wsl_path ("$Env:ProgramFiles/Docker/Docker/resources/docker.exe"))
        wsl -d ${devbox_wsl_distro_name} ln -nsf "${wsl_path_docker}" /usr/local/bin/docker

        # required for internal docker installation
        wsl -d $devbox_wsl_distro_name bash --login -c "echo '' >> ~/.bashrc && echo 'export DOCKER_HOST=tcp://127.0.0.1:2375' >> ~/.bashrc"
    }

    if (-not (Test-Path "$wsl_distro_dir/rootfs/usr/local/bin/docker-sync")) {
        wsl -d ${devbox_wsl_distro_name} gem install docker-sync | Out-Null

        # Replace one of docker-sync source files to avoid sync by starting and speedup project 'hot' start, initial precopy into clean volume still work by default
        $docker_sync_lib_sources_dir = (wsl -d $devbox_wsl_distro_name bash --login -c 'dirname $(gem which docker-sync)')
        Copy-Item "${devbox_root}/tools/bin/docker-sync/lib/docker-sync/sync_strategy/unison.rb" -Destination "$wsl_distro_dir/rootfs${docker_sync_lib_sources_dir}/docker-sync/sync_strategy/unison.rb" -Force

        # reset all windows paths as not required, besides /mnt/ pathes cause annoying warning of ruby shell about too open permission of such paths
        wsl -d $devbox_wsl_distro_name bash --login -c "echo '' >> ~/.bashrc && echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin' >> ~/.bashrc"
    }
}

function install_wsl_unison() {
    if (-not (Test-Path "$wsl_distro_dir/rootfs/usr/local/bin/unison")) {
        # map linux binary of unison as winos unison binary work not very well with both types of paths: winos and unix
        $wsl_path_unison = (get_wsl_path (Resolve-Path "$devbox_root/tools/bin/wsl/unison"))
        wsl -d ${devbox_wsl_distro_name} ln -nsf "${wsl_path_unison}" /usr/local/bin/unison
    }

    if (-not (Test-Path "$wsl_distro_dir/rootfs/usr/local/bin/unison-fsmonitor")) {
        # map linux binary of unison as winos unison binary work not very well with both types of paths: winos and unix
        $wsl_path_unison = (get_wsl_path (Resolve-Path "$devbox_root/tools/bin/wsl/unison-fsmonitor"))
        wsl -d ${devbox_wsl_distro_name} ln -nsf "${wsl_path_unison}" /usr/local/bin/unison-fsmonitor
    }
}

function install_cygwin() {

    if (-not (Test-Path "${cygwin_dir}/bin" -PathType Container) -or -not (Test-Path "${cygwin_dir}/bin/ruby.exe" -PathType Leaf) -or -not (Test-Path "${cygwin_dir}/bin/gem" -PathType Leaf)) {
        show_success_message "Downloading Cygwin program and installing ruby gems."

        if (-not (Test-Path "${download_dir}/cygwin_setup.exe" -PathType Leaf)) {
            $download_dir = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
            (new-object System.Net.WebClient).DownloadFile("https://cygwin.com/setup-x86_64.exe", "${download_dir}/cygwin_setup.exe")
        }

        # install cygwin with ruby packages required for docker-sync
        Start-Process -Wait -FilePath "${download_dir}/cygwin_setup.exe" -ArgumentList "--quiet-mode --no-admin --root=${cygwin_dir} --packages='openssl,ruby,ruby-devel,rubygems'"

        if (-not (Test-Path "${cygwin_dir}\home\$env:UserName\.bash_profile")) {
            New-Item -ItemType Directory -Path "${cygwin_dir}\home\$env:UserName" -Force | Out-Null
            New-Item -ItemType File -Path "${cygwin_dir}\home\$env:UserName\.bash_profile" -Force | Out-Null
        }
    }

    if (-not (Test-Path "C:\cygwin64" -PathType Container)) {
        show_error_message "Unable to install cygwin".
        exit
    }
}

function install_cygwin_docker_sync() {

    if (-not (Test-Path "${cygwin_dir}/home/$env:UserName/bin/docker-sync" -PathType Leaf)) {
        show_success_message "Installing Docker-sync inside Cygwin environment."

        @'
# DevBox PATHs for Cygwin
if [ -d "${HOME}/bin" ] ; then
  PATH="${HOME}/bin:${PATH}"
fi
PATH="$PATH:/cygdrive/c/ProgramData/DockerDesktop/version-bin"
PATH="$PATH:/cygdrive/c/Program Files/Docker/Docker/resources/bin"
# DevBox PATHs for Cygwin END
'@ | Add-Content "${cygwin_dir}\home\$env:UserName\.bash_profile"

        # replace \r\r with \n for unix file
        $text = [IO.File]::ReadAllText("${cygwin_dir}/home/$env:UserName/.bash_profile") -replace "`r`n", "`n"
        [IO.File]::WriteAllText("${cygwin_dir}/home/$env:UserName/.bash_profile", $text)

        # install docker-sync as ruby gem inside cygwin
        Start-Process -Wait -NoNewWindow -FilePath "${cygwin_dir}\bin\bash.exe" -ArgumentList "--login -c 'gem install docker-sync'"

        # Replace one of docker-sync source files to avoid sync by starting and speedup project 'hot' start, initial precopy into clean volume still work by default
        $docker_sync_lib_sources_dir = (& "${cygwin_dir}/bin/bash.exe" --login -c 'dirname $(gem which docker-sync)')
        Copy-Item "${devbox_root}/tools/bin/docker-sync/lib/docker-sync/sync_strategy/unison.rb" -Destination "${cygwin_dir}${docker_sync_lib_sources_dir}/docker-sync/sync_strategy/unison.rb" -Force

        # create symlink of missing '/etc/localtime' as docker-sync uses system time for comparisons
        & "${cygwin_dir}\bin\bash.exe" --login -c 'ln -nsf "/usr/share/zoneinfo/${TZ}" /etc/localtime'
    }
}

# Check and install unison
function install_cygwin_unison() {
    try {
        $_is_unison_installed = ((Test-Path "${cygwin_dir}\home\$env:UserName\.bash_profile") -and (Get-Content -Path "${cygwin_dir}\home\$env:UserName\.bash_profile" | Select-String -Pattern 'devbox/tools/bin'))
        # This command is more correct, but running cygwin bash profile takes takes 1-2 seconds on every launch
        # $_is_unison_installed = ((& C:\cygwin64\bin\bash.exe --login -c 'unison -version'))
    } catch {
        $_is_unison_installed = $false
    }

    if (-not ${_is_unison_installed}) {
        show_success_message "Installing Unison from DevBox tools."

        # evaluate cygwin path for devbox bin directory to add it to PATH env variable
        $devbox_bin_cygpath = (& "${cygwin_dir}\bin\bash.exe" --login -c "cygpath '${devbox_root}\tools\bin\cygwin'")

        # add unison to the beginning of PATHs to avoid using native cygwin unison if exist.
        # We need unison with the same ocaml version as inside docker-sync, otherwise unison cannot work
        ('PATH="' + ${devbox_bin_cygpath} + ':$PATH"') | Add-Content "${cygwin_dir}\home\$env:UserName\.bash_profile"

        # replace \r\r with \n for unix file after powershell updating
        $text = [IO.File]::ReadAllText("${cygwin_dir}\home\$env:UserName\.bash_profile") -replace "`r`n", "`n"
        [IO.File]::WriteAllText("${cygwin_dir}\home\$env:UserName\.bash_profile", $text)
    }
}

# Check and install composer
function install_composer() {
    try {
        # Composer version seems to be more logical, but no-plugins command is faster to ensure composer is presented in general
        $_is_composer_installed = ((composer --no-plugins))
    } catch {
        $_is_composer_installed = $false
    }

    if (-not $_is_composer_installed) {
        Start-Process PowerShell -Wait -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass", "$env:ChocolateyInstall/bin/choco install -y composer"

        $env:devbox_env_path_updated = $true
    } else {
        composer install --quiet
    }
}

function install_extra_packages() {
    # You can install additional packages here
}

function add_directory_to_env_path($_bin_dir) {
    if (-not $_bin_dir -or -not (Test-Path $_bin_dir)) {
        show_error_message "Unable to update system PATH. Path to binaries is empty or does not exist '${_bin_dir}'."
    }

    # add new binaries path to env variables of current shell
    $env:Path += ";${_bin_dir}"

    # save new binaries path to permanent user env variables storage to avoid cleaning
    $current_env_path = ([Environment]::getEnvironmentVariable('PATH', 'User'));
    [Environment]::SetEnvironmentVariable('PATH', "${current_env_path};${_bin_dir};", 'User')

    $env:devbox_env_path_updated = $true
}

function register_devbox_scripts_globally() {
    $devbox_root_envpath = (${devbox_root} -Replace '/', '\')
    if (-not ($env:Path | Select-String -Pattern "$([regex]::Escape(${devbox_root_envpath}));")) {
        add_directory_to_env_path "${devbox_root_envpath}"
    }
}

############################ Local functions end ############################

. require_once "${devbox_root}/tools/project/project-dotenv.ps1"
. require_once "${devbox_root}/tools/project/nginx-reverse-proxy-configs.ps1"
. require_once "${devbox_root}/tools/project/docker-up-configs.ps1"
. require_once "${devbox_root}/tools/project/platform-tools.ps1"
. require_once "${devbox_root}/tools/project/all-projects.ps1"
. require_once "${devbox_root}/tools/docker/docker-compose.ps1"
. require_once "${devbox_root}/tools/docker/docker-sync.ps1"
. require_once "${devbox_root}/tools/docker/docker.ps1"
. require_once "${devbox_root}/tools/system/dotenv.ps1"
. require_once "${devbox_root}/tools/system/hosts.ps1"

############################ Public functions ############################

function start_project() {
    show_success_message "Generating project file .env and variables" "2"
    prepare_project_dotenv_variables $true

    show_success_message "Creating missing project directories" "2"
    create_base_project_dirs

    show_success_message "Preparing required project docker-up configs" "2"
    prepare_project_docker_up_configs

    show_success_message "Preparing nginx-reverse-proxy configs" "2"
    prepare_project_nginx_reverse_proxy_configs

    show_success_message "Starting data synchronization" "2"
    docker_sync_start_all_directory_volumes "$project_up_dir"

    show_success_message "Starting project docker container" "2"
    docker_compose_up_all_directory_services "$project_up_dir" "$project_up_dir/.env"

    show_success_message "Adding domains to hosts file" "2"
    $domains = if (-not ${WEBSITE_EXTRA_HOST_NAMES}) { ${WEBSITE_HOST_NAME} } else { "${WEBSITE_HOST_NAME},${WEBSITE_EXTRA_HOST_NAMES}" }
    add_website_domain_to_hosts "$domains"

    # Fix for reload network,because devbox-network contains all containers
    sleep 5
    show_success_message "Restarting nginx-reverse-proxy" "2"
    nginx_reverse_proxy_restart
}

function stop_current_project() {
    if (-not (Test-Path $project_up_dir -PathType Container) -or ! ((Get-ChildItem -Path $project_up_dir -Filter "docker-*.yml" -Depth 1 | Measure-Object).Count)) {
        return
    }

    show_success_message "Preparing project variables from .env" "2"
    prepare_project_dotenv_variables $false

    show_success_message "Stopping project docker containers" "2"
    docker_compose_stop_all_directory_services "$project_up_dir" "$project_up_dir/.env"
    #    docker_compose_down_all_directory_services "$project_up_dir" "$project_up_dir/.env"

    show_success_message "Stopping data syncing" "2"
    docker_sync_stop_all_directory_volumes "$project_up_dir"

    show_success_message "Cleaning nginx-reverse-proxy configs" "2"
    cleanup_project_nginx_reverse_proxy_configs

    if (is_docker_container_running 'nginx-reverse-proxy') {
        show_success_message "Restarting nginx-reverse-proxy" "2"
        nginx_reverse_proxy_restart
    }

    show_success_message "Removing domains from hosts file" "2"
    $domains = if (-not ${WEBSITE_EXTRA_HOST_NAMES}) { ${WEBSITE_HOST_NAME} } else { "${WEBSITE_HOST_NAME},${WEBSITE_EXTRA_HOST_NAMES}" }
    delete_website_domain_from_hosts "$domains"

    dotenv_unset_variables "$project_up_dir/.env"

    Remove-Variable -Name "selected_project" -Scope Global
    Remove-Variable -Name "project_dir" -Scope Global
    Remove-Variable -Name "project_up_dir" -Scope Global
}

function down_and_clean_current_project() {
    show_success_message "Preparing project variables from .env" "2"
    prepare_project_dotenv_variables $false

    if (Get-ChildItem -Path ${project_up_dir} -Filter "docker-compose-*.yml" -Depth 1) {
        show_success_message "Stopping docker containers and removing volumes" "2"
        docker_compose_down_and_clean_all_directory_services "${project_up_dir}" "${project_up_dir}/.env"
    }

    if (Get-ChildItem -Path ${project_up_dir} -Filter "docker-sync-*.yml" -Depth 1) {
        show_success_message "Stopping data syncing" "2"
        docker_sync_stop_all_directory_volumes "${project_up_dir}"

        show_success_message "Cleaning sync volumes" "2"
        docker_sync_clean_all_directory_volumes "${project_up_dir}"
    }

    show_success_message "Cleaning nginx-reverse-proxy configs" "2"
    cleanup_project_nginx_reverse_proxy_configs

    if (is_docker_container_running 'nginx-reverse-proxy') {
        show_success_message "Restarting nginx-reverse-proxy" "2"
        nginx_reverse_proxy_restart
    }

    show_success_message "Cleaning project docker-up configs" "2"
    cleanup_project_docker_up_configs

    show_success_message "Removing domains from hosts file" "2"
    $domains = if (-not ${WEBSITE_EXTRA_HOST_NAMES}) { ${WEBSITE_HOST_NAME} } else { "${WEBSITE_HOST_NAME},${WEBSITE_EXTRA_HOST_NAMES}" }
    delete_website_domain_from_hosts "$domains"

    dotenv_unset_variables "$project_up_dir/.env"

    show_success_message "Deleting generated .env file" "2"
    # remove dotenv in the end as it is the main project configuration file
    Remove-Item "$project_up_dir/.env" -Force -ErrorAction Ignore

    Remove-Variable -Name "selected_project" -Scope Global
    Remove-Variable -Name "project_dir" -Scope Global
    Remove-Variable -Name "project_up_dir" -Scope Global
}

function init_selected_project($_selected_project = "") {
    if (-not $_selected_project) {
        show_error_message "Unable to initialize selected project. Name cannot be empty"
        exit 1
    }

    ensure_project_configured "${_selected_project}"

    $project_dir = "${devbox_projects_dir}/${_selected_project}"
    $project_up_dir = "$project_dir/docker-up"

    Set-Variable -Name "selected_project" -Value $_selected_project -Scope Global
    Set-Variable -Name "project_dir" -Value $project_dir -Scope Global
    Set-Variable -Name "project_up_dir" -Value $project_up_dir -Scope Global
}

############################ Public functions end ############################

############################ Local functions ############################

function create_base_project_dirs() {
    New-Item -ItemType Directory -Path "${project_up_dir}" -Force | Out-Null

    New-Item -ItemType Directory -Path "${project_dir}/public_html/" -Force | Out-Null
    New-Item -ItemType Directory -Path "${project_dir}/share/" -Force | Out-Null
    New-Item -ItemType Directory -Path "${project_dir}/sysdumps/" -Force | Out-Null


    New-Item -ItemType Directory -Path "${project_dir}/share/composer" -Force | Out-Null
    $_composer_readme_path = "${project_dir}/share/composer/readme.txt"
    if (-not (Test-Path ${_composer_readme_path} -PathType Leaf)) {
        Add-Content -Path ${_composer_readme_path} -Value "This directory content will be copied into '/var/www/.composer' inside container (see bashrc configs bashrc_www-data)."
        Add-Content -Path ${_composer_readme_path} -Value "You can put your composer auth.json here if required."
    }

    New-Item -ItemType Directory -Path "${project_dir}/share/ssh" -Force | Out-Null
    $_ssh_readme_path = "${project_dir}/share/ssh/readme.txt"
    if (-not (Test-Path ${_ssh_readme_path} -PathType Leaf)) {
        New-Item -Path ${_ssh_readme_path} -Force | Out-Null
        Add-Content -Path ${_ssh_readme_path} -Value "Content of this directory will be copied into '/var/www/.ssh' inside container with permissions updating (see bashrc configs bashrc_www-data)."
        Add-Content -Path ${_ssh_readme_path} -Value "You can put your ssh keys here if required."
    }

    New-Item -ItemType Directory -Path "${project_dir}/sysdumps/composer/" -Force | Out-Null

    New-Item -ItemType Directory -Path "${project_dir}/sysdumps/node_modules/" -Force | Out-Null

    if (${MYSQL_ENABLE} -eq "yes") {
        New-Item -ItemType Directory -Path "${project_dir}/sysdumps/mysql" -Force | Out-Null
    }

    if (${ELASTICSEARCH_ENABLE} -eq "yes") {
        New-Item -ItemType Directory -Path "${project_dir}/sysdumps/elasticsearch" -Force | Out-Null
    }

    # backward compatibility ont-time moves, will be removed later
    # "db/", "es/", "node_modules/" directories were moved into project "sysdumps/" dir
    if ((Test-Path "${project_dir}/db/" -PathType Container) -and (-not (Test-Path "${project_dir}/sysdumps/mysql/" -PathType Container) -or ! (Test-Path "${project_dir}/sysdumps/mysql/*"))) {
        #remove target directory to move without duplicated subdirectories
        Remove-Item "${project_dir}/sysdumps/mysql" -Force
        Move-Item -Path "${project_dir}/db" -Destination "${project_dir}/sysdumps/mysql"
    }

    if ((Test-Path "${project_dir}/sysdumps/db/" -PathType Container) -and (-not (Test-Path "${project_dir}/sysdumps/mysql/" -PathType Container) -or ! (Test-Path "${project_dir}/sysdumps/mysql/*"))) {
        #remove target directory to move without duplicated subdirectories
        Remove-Item "${project_dir}/sysdumps/mysql" -Force
        Move-Item -Path "${project_dir}/sysdumps/db" -Destination "${project_dir}/sysdumps/mysql"
    }

    if ((Test-Path "${project_dir}/es/" -PathType Container) -and (-not (Test-Path "${project_dir}/sysdumps/elasticsearch/" -PathType Container) -or ! (Test-Path "${project_dir}/sysdumps/elasticsearch/*"))) {
        #remove target directory to move without duplicated subdirectories
        Remove-Item "${project_dir}/sysdumps/elasticsearch" -Force
        Move-Item -Path "${project_dir}/es" -Destination "${project_dir}/sysdumps/elasticsearch"
    }

    if ((Test-Path "${project_dir}/sysdumps/es/" -PathType Container) -and (-not (Test-Path "${project_dir}/sysdumps/elasticsearch/" -PathType Container) -or ! (Test-Path "${project_dir}/sysdumps/elasticsearch/*"))) {
        #remove target directory to move without duplicated subdirectories
        Remove-Item "${project_dir}/sysdumps/elasticsearch" -Force
        Move-Item -Path "${project_dir}/sysdumps/es" -Destination "${project_dir}/sysdumps/elasticsearch"
    }

    if ((Test-Path "${project_dir}/node_modules/" -PathType Container) -and (-not (Test-Path "${project_dir}/sysdumps/node_modules/" -PathType Container) -or ! (Test-Path "${project_dir}/sysdumps/node_modules/*"))) {
        #remove target directory to move without duplicated subdirectories
        Remove-Item "${project_dir}/sysdumps/node_modules" -Force
        Move-Item -Path "${project_dir}/node_modules" -Destination "${project_dir}/sysdumps/node_modules"
    }
}

############################ Local functions end ############################

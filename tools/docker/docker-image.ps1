. require_once "${devbox_root}/tools/system/constants.ps1"
. require_once "${devbox_root}/tools/system/output.ps1"

############################ Public functions ############################

# find existing docker images without certain tags and refresh image(':latest' only)
function refresh_existing_docker_images() {
    $_docker_images = Invoke-Expression "docker image list --filter='reference=*/*:latest' --format='{{.Repository}}'"

    foreach ($_docker_image in ${_docker_images}) {
        if (-not ($docker_images_autoupdate_skip_images | Select-String -Pattern ${_docker_image})) {
            docker_image_pull ${_docker_image}
        }
    }
}

# refresh (pull) the given docker image
function docker_image_pull($_image_name = "") {
    if (-not $_image_name) {
        show_error_message "Unable to pull docker image. Name cannot be empty."
        exit
    }

    Invoke-Expression "docker pull '${_image_name}:latest' "
}

############################ Public functions end ############################

. require_once "${devbox_root}/tools/system/output.ps1"

function print_info() {
    show_message ""
    show_message ""
    print_section_header "Project Information"

    show_message ""
    show_message "[ WEBSITE ]"
    show_message ""

    show_info_value_message "Project Name" ${PROJECT_NAME}
    show_info_value_message "Frontend URL" (get_website_urls)
    show_info_value_message "Website Remote Application Root" ${WEBSITE_APPLICATION_ROOT}
    show_info_value_message "Web Container Connection" "docker exec -it ${PROJECT_NAME}_${CONTAINER_WEB_NAME} /bin/bash"

    if (${MYSQL_ENABLE} -eq "yes") {
        show_message ""
        show_message "[ MYSQL ]"
        show_message ""
        show_info_value_message "Database Name" ${CONTAINER_MYSQL_DB_NAME}
        show_info_value_message "Database credentials" "root / ${CONTAINER_MYSQL_ROOT_PASS}"
        show_info_value_message "[INSIDE]  DB Connection" "mysql -u'root' -p'${CONTAINER_MYSQL_ROOT_PASS}' -h ${PROJECT_NAME}_${CONTAINER_MYSQL_NAME}"
        show_info_value_message "[OUTSIDE] DB Connection" "mysql -u'root' -p'${CONTAINER_MYSQL_ROOT_PASS}' -h ${MACHINE_IP_ADDRESS} -P ${CONTAINER_MYSQL_PORT}"
    }

    if (${REDIS_ENABLE} -eq "yes") {
        show_message ""
        show_message "[ REDIS ]"
        show_message ""
        show_info_value_message "Redis Host" "${PROJECT_NAME}_${CONTAINER_REDIS_NAME}"
        show_info_value_message "Redis Connection" "redis-cli -h ${PROJECT_NAME}_${CONTAINER_REDIS_NAME}"
    }

    if (${ELASTICSEARCH_ENABLE} -eq "yes") {
        show_message ""
        show_message "[ ELASTICSEARCH ]"
        show_message ""
        show_info_value_message "ElasticSearch Host" "${PROJECT_NAME}_${CONTAINER_ELASTICSEARCH_NAME}"
        show_info_value_message "ElasticSearch Port" "${CONTAINER_ELASTICSEARCH_PORT}"
    }
    
    if (${OPENSEARCH_ENABLE} -eq "yes") {
        show_message ""
        show_message "[ OPENSEARCH ]"
        show_message ""
        show_info_value_message "OpenSearch Host" "${PROJECT_NAME}_${CONTAINER_OPENSEARCH_NAME}"
        show_info_value_message "OpenSearch Port" "${CONTAINER_OPENSEARCH_PORT}"
    }

    if (${MONGODB_ENABLE} -eq "yes") {
        show_message ""
        show_message "[ MONGODB ]"
        show_message ""
        show_info_value_message "MongoDB Host" "${PROJECT_NAME}_${CONTAINER_MONGODB_NAME}"
    }

    if (${POSTGRES_ENABLE} -eq "yes") {
        show_message ""
        show_message "[ POSTGRES ]"
        show_message ""
        show_info_value_message "Postgres Host" "${PROJECT_NAME}_${CONTAINER_POSTGRES_NAME}"
    }

    if (${RABBITMQ_ENABLE} -eq "yes") {
        show_message ""
        show_message "[ RABBITMQ ]"
        show_message ""
        show_info_value_message "RabbitMQ Host" "${PROJECT_NAME}_${CONTAINER_RABBITMQ_NAME}"
        show_info_value_message "RabbitMQ Port" "${CONTAINER_RABBITMQ_PORT}"
        show_info_value_message "RabbitMQ URL" "http://${MACHINE_IP_ADDRESS}:1${CONTAINER_RABBITMQ_PORT}/"
    }

    show_message ""
    show_message "[ PORTAINER ]"
    show_message ""
    show_info_value_message "Portainer URL" "http://${MACHINE_IP_ADDRESS}:${PORTAINER_PORT}/"

    if (${MAILER_TYPE} -eq 'mailhog') {
        show_message ""
        show_message "[ MAILHOG ]"
        show_message ""
        show_info_value_message "MailHog URL" "http://${MACHINE_IP_ADDRESS}:${MAILHOG_PORT}/"
    }

    show_message ""
    print_section_footer
    show_message ""
}

function get_website_urls() {
    $_domains = if (-not ${WEBSITE_EXTRA_HOST_NAMES}) { ${WEBSITE_HOST_NAME} } else { "${WEBSITE_HOST_NAME},${WEBSITE_EXTRA_HOST_NAMES}" }

    $_urls = @()
    foreach ($_domain in $_domains.Split(",")) {
        $_urls += "${WEBSITE_PROTOCOL}://${_domain}/"
    }

    return [string]::Join(', ', $_urls)
}

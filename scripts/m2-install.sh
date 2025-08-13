#!/bin/bash

# Magento 2.4.x Installation Script for Docker Environment
# This script installs and configures Magento 2.4.x with all required services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for service to be ready
wait_for_service() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=1

    print_status "Waiting for $service to be ready on port $port..."

    while [ $attempt -le $max_attempts ]; do
        if command_exists nc; then
            if nc -z localhost $port 2>/dev/null; then
                print_success "$service is ready!"
                return 0
            fi
        else
            # Fallback to /dev/tcp if nc is not available
            if timeout 1 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
                print_success "$service is ready!"
                return 0
            fi
        fi

        print_status "Attempt $attempt/$max_attempts: $service not ready yet, waiting 10 seconds..."
        sleep 10
        attempt=$((attempt + 1))
    done

    print_error "$service failed to start after $max_attempts attempts"
    return 1
}

# Function to check environment variables
check_env_vars() {
    local required_vars=(
        "MAGENTO_ADMIN_USER"
        "MAGENTO_ADMIN_PASSWORD"
        "MAGENTO_ADMIN_EMAIL"
        "MAGENTO_ADMIN_FIRSTNAME"
        "MAGENTO_ADMIN_LASTNAME"
        "MAGENTO_BASE_URL"
        "MAGENTO_SECURE_BASE_URL"
        "MYSQL_DATABASE"
        "MYSQL_USER"
        "MYSQL_PASSWORD"
        "MYSQL_HOST"
        "REDIS_HOST"
        "OPENSEARCH_HOST"
        "RABBITMQ_HOST"
    )

    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi

    print_success "All required environment variables are set"
}

# Function to wait for all services
wait_for_services() {
    print_status "Waiting for all services to be ready..."

    # Wait for MariaDB
    wait_for_service "MariaDB" 3306

    # Wait for Redis
    wait_for_service "Redis" 6379

    # Wait for RabbitMQ
    wait_for_service "RabbitMQ" 5672

    # Wait for OpenSearch
    wait_for_service "OpenSearch" 9200

    print_success "All services are ready!"
}

# Function to install Magento via Composer
install_magento_composer() {
    print_status "Installing Magento via Composer..."

    # Set Composer authentication if provided
    if [ -n "$COMPOSER_AUTH_USERNAME" ] && [ -n "$COMPOSER_AUTH_PASSWORD" ]; then
        composer config --global http-basic.repo.magento.com "$COMPOSER_AUTH_USERNAME" "$COMPOSER_AUTH_PASSWORD"
    fi

    # Create Magento project
    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:${MAGENTO_VERSION:-2.4.7} .

    print_success "Magento downloaded via Composer"
}

# Function to install Magento via Magento CLI
install_magento_cli() {
    print_status "Installing Magento via CLI..."

    # Set proper permissions
    chmod +x bin/magento

    # Install Magento
    php bin/magento setup:install \
        --base-url="${MAGENTO_BASE_URL}/" \
        --base-url-secure="${MAGENTO_SECURE_BASE_URL}/" \
        --use-secure=1 \
        --use-secure-admin=1 \
        --db-host="${MYSQL_HOST}" \
        --db-name="${MYSQL_DATABASE}" \
        --db-user="${MYSQL_USER}" \
        --db-password="${MYSQL_PASSWORD}" \
        --admin-firstname="${MAGENTO_ADMIN_FIRSTNAME}" \
        --admin-lastname="${MAGENTO_ADMIN_LASTNAME}" \
        --admin-email="${MAGENTO_ADMIN_EMAIL}" \
        --admin-user="${MAGENTO_ADMIN_USER}" \
        --admin-password="${MAGENTO_ADMIN_PASSWORD}" \
        --backend-frontname="${MAGENTO_BACKEND_NAME:-admin}" \
        --language=en_US \
        --currency=USD \
        --timezone=America/New_York \
        --use-rewrites=1 \
        --search-engine=opensearch \
        --opensearch-host="${OPENSEARCH_HOST}" \
        --opensearch-port=9200 \
        --opensearch-index-prefix=magento2 \
        --opensearch-enable-auth=0 \
        --opensearch-username="${OPENSEARCH_USERNAME:-admin}" \
        --opensearch-password="${OPENSEARCH_PASSWORD:-admin123}" \
        --amqp-host="${RABBITMQ_HOST}" \
        --amqp-port=5672 \
        --amqp-user="${RABBITMQ_DEFAULT_USER:-admin}" \
        --amqp-password="${RABBITMQ_DEFAULT_PASS:-admin123}" \
        --amqp-virtualhost=/ \
        --session-save=redis \
        --session-save-redis-host="${REDIS_HOST}" \
        --session-save-redis-port=6379 \
        --session-save-redis-db=2 \
        --session-save-redis-password="${REDIS_PASSWORD:-}" \
        --cache-backend=redis \
        --cache-backend-redis-server="${REDIS_HOST}" \
        --cache-backend-redis-port=6379 \
        --cache-backend-redis-db=0 \
        --cache-backend-redis-password="${REDIS_PASSWORD:-}" \
        --page-cache=redis \
        --page-cache-redis-server="${REDIS_HOST}" \
        --page-cache-redis-port=6379 \
        --page-cache-redis-db=1 \
        --page-cache-redis-password="${REDIS_PASSWORD:-}" \
        --magento-init-params="MAGE_MODE=${MAGENTO_MODE:-production}"

    print_success "Magento installed successfully"
}

# Function to configure Varnish
configure_varnish() {
    print_status "Configuring Varnish..."

    # Enable Varnish in Magento
    php bin/magento config:set system/full_page_cache/caching_application 2

    # Set Varnish backend host
    php bin/magento config:set system/full_page_cache/varnish/access_list "localhost"

    # Set Varnish backend port
    php bin/magento config:set system/full_page_cache/varnish/backend_host "${VARNISH_BACKEND_HOST:-nginx}"
    php bin/magento config:set system/full_page_cache/varnish/backend_port "${VARNISH_BACKEND_PORT:-80}"

    print_success "Varnish configured successfully"
}

# Function to configure Redis
configure_redis() {
    print_status "Configuring Redis..."

    # Configure Redis for sessions
    php bin/magento config:set system/redis/disable_logging 1
    php bin/magento config:set system/redis/host "${REDIS_HOST}"
    php bin/magento config:set system/redis/port 6379
    php bin/magento config:set system/redis/password "${REDIS_PASSWORD:-}"
    php bin/magento config:set system/redis/database 2
    php bin/magento config:set system/redis/compression_threshold 2048
    php bin/magento config:set system/redis/compression_lib lzf
    php bin/magento config:set system/redis/log_level 1
    php bin/magento config:set system/redis/max_concurrency 6
    php bin/magento config:set system/redis/break_after_frontend 5
    php bin/magento config:set system/redis/break_after_adminhtml 30
    php bin/magento config:set system/redis/first_lifetime 600
    php bin/magento config:set system/redis/bot_first_lifetime 7200
    php bin/magento config:set system/redis/bot_lifetime 7200
    php bin/magento config:set system/redis/disable_lua 0
    php bin/magento config:set system/redis/lua_script ""
    php bin/magento config:set system/redis/compression_lib lzf

    # Configure Redis for cache
    php bin/magento config:set system/full_page_cache/redis_server "${REDIS_HOST}"
    php bin/magento config:set system/full_page_cache/redis_port 6379
    php bin/magento config:set system/full_page_cache/redis_password "${REDIS_PASSWORD:-}"
    php bin/magento config:set system/full_page_cache/redis_database 1
    php bin/magento config:set system/full_page_cache/redis_compression_threshold 2048
    php bin/magento config:set system/full_page_cache/redis_compression_lib lzf
    php bin/magento config:set system/full_page_cache/redis_log_level 1
    php bin/magento config:set system/full_page_cache/redis_max_concurrency 6
    php bin/magento config:set system/full_page_cache/redis_break_after_frontend 5
    php bin/magento config:set system/full_page_cache/redis_break_after_adminhtml 30
    php bin/magento config:set system/full_page_cache/redis_first_lifetime 600
    php bin/magento config:set system/full_page_cache/redis_bot_first_lifetime 7200
    php bin/magento config:set system/full_page_cache/redis_bot_lifetime 7200
    php bin/magento config:set system/full_page_cache/redis_disable_lua 0
    php bin/magento config:set system/full_page_cache/redis_lua_script ""

    print_success "Redis configured successfully"
}

# Function to configure OpenSearch
configure_opensearch() {
    print_status "Configuring OpenSearch..."

    # Configure OpenSearch
    php bin/magento config:set catalog/search/engine opensearch
    php bin/magento config:set catalog/search/opensearch_server_hostname "${OPENSEARCH_HOST}"
    php bin/magento config:set catalog/search/opensearch_server_port 9200
    php bin/magento config:set catalog/search/opensearch_index_prefix magento2
    php bin/magento config:set catalog/search/opensearch_enable_auth 0
    php bin/magento config:set catalog/search/opensearch_username "${OPENSEARCH_USERNAME:-admin}"
    php bin/magento config:set catalog/search/opensearch_password "${OPENSEARCH_PASSWORD:-admin123}"
    php bin/magento config:set catalog/search/opensearch_server_protocol http
    php bin/magento config:set catalog/search/opensearch_server_timeout 15

    print_success "OpenSearch configured successfully"
}

# Function to configure RabbitMQ
configure_rabbitmq() {
    print_status "Configuring RabbitMQ..."

    # Configure RabbitMQ
    php bin/magento config:set system/queue/amqp/host "${RABBITMQ_HOST}"
    php bin/magento config:set system/queue/amqp/port 5672
    php bin/magento config:set system/queue/amqp/user "${RABBITMQ_DEFAULT_USER:-admin}"
    php bin/magento config:set system/queue/amqp/password "${RABBITMQ_DEFAULT_PASS:-admin123}"
    php bin/magento config:set system/queue/amqp/virtualhost /
    php bin/magento config:set system/queue/amqp/ssl false
    php bin/magento config:set system/queue/amqp/ssl_options '{"verify_peer":false,"verify_peer_name":false}'

    print_success "RabbitMQ configured successfully"
}

# Function to configure email
configure_email() {
    print_status "Configuring email settings..."

    # Configure SMTP settings
    if [ -n "$SMTP_HOST" ]; then
        php bin/magento config:set system/smtp/disable 0
        php bin/magento config:set system/smtp/host "${SMTP_HOST}"
        php bin/magento config:set system/smtp/port "${SMTP_PORT:-1025}"
        php bin/magento config:set system/smtp/set_return_path 0
        php bin/magento config:set system/smtp/return_path_email ""
        php bin/magento config:set system/smtp/username "${SMTP_USERNAME:-}"
        php bin/magento config:set system/smtp/password "${SMTP_PASSWORD:-}"
        php bin/magento config:set system/smtp/ssl "${SMTP_ENCRYPTION:-none}"
    else
        php bin/magento config:set system/smtp/disable 1
    fi

    print_success "Email settings configured successfully"
}

# Function to set production mode
set_production_mode() {
    print_status "Setting production mode..."

    php bin/magento deploy:mode:set production

    print_success "Production mode set successfully"
}

# Function to compile and deploy
compile_and_deploy() {
    print_status "Compiling and deploying..."

    # Compile code
    php bin/magento setup:di:compile

    # Deploy static content
    php bin/magento setup:static-content:deploy -f

    # Setup upgrade
    php bin/magento setup:upgrade

    print_success "Compilation and deployment completed"
}

# Function to set proper permissions
set_permissions() {
    print_status "Setting proper permissions..."

    # Set ownership
    chown -R magento:www-data .

    # Set directory permissions
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
    find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +

    # Set specific permissions for sensitive directories
    chmod 755 app/etc
    chmod 644 app/etc/*.xml

    print_success "Permissions set successfully"
}

# Function to create cron job
setup_cron() {
    print_status "Setting up cron job..."

    # Add Magento cron to crontab
    (crontab -l 2>/dev/null; echo "*/60 * * * * cd /var/www/html && php bin/magento cron:run") | crontab -

    print_success "Cron job set up successfully"
}

# Function to start queue consumers
start_queue_consumers() {
    print_status "Starting queue consumers..."

    # Start async operations consumer
    php bin/magento queue:consumers:start async.operations.all --max-messages=1000 &

    print_success "Queue consumers started"
}

# Function to reindex
reindex() {
    print_status "Reindexing..."

    php bin/magento indexer:reindex

    print_success "Reindexing completed"
}

# Function to flush cache
flush_cache() {
    print_status "Flushing cache..."

    php bin/magento cache:flush

    print_success "Cache flushed successfully"
}

# Main installation function
main() {
    print_status "Starting Magento 2.4.x installation..."

    # Check environment variables
    check_env_vars

    # Wait for services
    wait_for_services

    # Install Magento if not already installed
    if [ ! -f "app/etc/env.php" ]; then
        print_status "Magento not found, installing..."

        # Install via Composer if composer.json doesn't exist
        if [ ! -f "composer.json" ]; then
            install_magento_composer
        fi

        # Install via CLI
        install_magento_cli

        # Configure services
        configure_varnish
        configure_redis
        configure_opensearch
        configure_rabbitmq
        configure_email

        # Set production mode
        set_production_mode

        # Compile and deploy
        compile_and_deploy

        # Set permissions
        set_permissions

        # Setup cron
        setup_cron

        # Start queue consumers
        start_queue_consumers

        # Reindex
        reindex

        # Flush cache
        flush_cache

        print_success "Magento installation completed successfully!"
    else
        print_status "Magento already installed, updating configuration..."

        # Update configuration
        configure_varnish
        configure_redis
        configure_opensearch
        configure_rabbitmq
        configure_email

        # Compile and deploy
        compile_and_deploy

        # Set permissions
        set_permissions

        # Reindex
        reindex

        # Flush cache
        flush_cache

        print_success "Magento configuration updated successfully!"
    fi

    print_success "Installation script completed!"
}

# Run main function
main "$@"

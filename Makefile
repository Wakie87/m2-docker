# Magento 2.4.x Docker Environment Makefile
# This Makefile provides commands for managing the Docker environment

.PHONY: help up down install reindex cache-flush xdebug-on xdebug-off logs shell backup restore clean

# Default target
help:
	@echo "Magento 2.4.x Docker Environment Management"
	@echo "=========================================="
	@echo ""
	@echo "Available commands:"
	@echo "  up              - Start all services"
	@echo "  down            - Stop all services"
	@echo "  restart         - Restart all services"
	@echo "  install         - Install Magento 2.4.x"
	@echo "  reindex         - Reindex Magento"
	@echo "  cache-flush     - Flush Magento cache"
	@echo "  cache-clean     - Clean Magento cache"
	@echo "  cache-status    - Show cache status"
	@echo "  xdebug-on       - Enable Xdebug"
	@echo "  xdebug-off      - Disable Xdebug"
	@echo "  logs            - Show all logs"
	@echo "  logs-nginx      - Show Nginx logs"
	@echo "  logs-php        - Show PHP-FPM logs"
	@echo "  logs-mysql      - Show MariaDB logs"
	@echo "  logs-redis      - Show Redis logs"
	@echo "  logs-opensearch - Show OpenSearch logs"
	@echo "  logs-varnish    - Show Varnish logs"
	@echo "  shell           - Open shell in PHP container"
	@echo "  shell-mysql     - Open shell in MariaDB container"
	@echo "  shell-redis     - Open shell in Redis container"
	@echo "  backup          - Create backup (DB + media)"
	@echo "  restore         - Restore from backup"
	@echo "  clean           - Clean up volumes and containers"
	@echo "  status          - Show service status"
	@echo "  health          - Check service health"
	@echo "  update          - Update Magento and dependencies"
	@echo "  setup-dev       - Setup development environment"
	@echo "  setup-prod      - Setup production environment"

# Start all services
up:
	@echo "Starting Magento 2.4.x Docker environment..."
	docker-compose up -d
	@echo "Services started. Waiting for them to be ready..."
	@echo "You can check status with: make status"
	@echo "View logs with: make logs"

# Stop all services
down:
	@echo "Stopping Magento 2.4.x Docker environment..."
	docker-compose down
	@echo "Services stopped"

# Restart all services
restart:
	@echo "Restarting Magento 2.4.x Docker environment..."
	docker-compose restart
	@echo "Services restarted"

# Install Magento 2.4.x
install:
	@echo "Installing Magento 2.4.x..."
	docker-compose exec php-fpm bash -c "cd /var/www/html && chmod +x scripts/m2-install.sh && ./scripts/m2-install.sh"
	@echo "Magento installation completed!"

# Reindex Magento
reindex:
	@echo "Reindexing Magento..."
	docker-compose exec php-fpm php bin/magento indexer:reindex
	@echo "Reindexing completed!"

# Flush Magento cache
cache-flush:
	@echo "Flushing Magento cache..."
	docker-compose exec php-fpm php bin/magento cache:flush
	@echo "Cache flushed!"

# Clean Magento cache
cache-clean:
	@echo "Cleaning Magento cache..."
	docker-compose exec php-fpm php bin/magento cache:clean
	@echo "Cache cleaned!"

# Show cache status
cache-status:
	@echo "Magento cache status:"
	docker-compose exec php-fpm php bin/magento cache:status

# Enable Xdebug
xdebug-on:
	@echo "Enabling Xdebug..."
	docker-compose exec php-fpm bash -c "echo 'xdebug.mode=debug' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
	docker-compose exec php-fpm bash -c "echo 'xdebug.start_with_request=yes' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
	@echo "Xdebug enabled. Restarting PHP-FPM..."
	docker-compose restart php-fpm
	@echo "Xdebug is now enabled!"

# Disable Xdebug
xdebug-off:
	@echo "Disabling Xdebug..."
	docker-compose exec php-fpm bash -c "sed -i '/xdebug.mode=debug/d' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
	docker-compose exec php-fpm bash -c "sed -i '/xdebug.start_with_request=yes/d' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
	@echo "Xdebug disabled. Restarting PHP-FPM..."
	docker-compose restart php-fpm
	@echo "Xdebug is now disabled!"

# Show all logs
logs:
	@echo "Showing all service logs..."
	docker-compose logs -f

# Show Nginx logs
logs-nginx:
	@echo "Showing Nginx logs..."
	docker-compose logs -f nginx

# Show PHP-FPM logs
logs-php:
	@echo "Showing PHP-FPM logs..."
	docker-compose logs -f php-fpm

# Show MariaDB logs
logs-mysql:
	@echo "Showing MariaDB logs..."
	docker-compose logs -f mariadb

# Show Redis logs
logs-redis:
	@echo "Showing Redis logs..."
	docker-compose logs -f redis

# Show OpenSearch logs
logs-opensearch:
	@echo "Showing OpenSearch logs..."
	docker-compose logs -f opensearch

# Show Varnish logs
logs-varnish:
	@echo "Showing Varnish logs..."
	docker-compose logs -f varnish

# Open shell in PHP container
shell:
	@echo "Opening shell in PHP container..."
	docker-compose exec php-fpm bash

# Open shell in MariaDB container
shell-mysql:
	@echo "Opening shell in MariaDB container..."
	docker-compose exec mariadb bash

# Open shell in Redis container
shell-redis:
	@echo "Opening shell in Redis container..."
	docker-compose exec redis sh

# Create backup
backup:
	@echo "Creating backup..."
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@echo "Backing up database..."
	docker-compose exec mariadb mysqldump -u root -p$(shell grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2) $(shell grep MYSQL_DATABASE .env | cut -d '=' -f2) > backups/$(shell date +%Y%m%d_%H%M%S)/database.sql
	@echo "Backing up media files..."
	tar -czf backups/$(shell date +%Y%m%d_%H%M%S)/media.tar.gz volumes/magento/media/
	@echo "Backup completed in backups/$(shell date +%Y%m%d_%H%M%S)/"

# Restore from backup
restore:
	@echo "Available backups:"
	@ls -la backups/
	@echo "Please specify backup directory: make restore BACKUP_DIR=backups/YYYYMMDD_HHMMSS"
	@if [ -z "$(BACKUP_DIR)" ]; then exit 1; fi
	@echo "Restoring from $(BACKUP_DIR)..."
	@echo "Restoring database..."
	docker-compose exec -T mariadb mysql -u root -p$(shell grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2) $(shell grep MYSQL_DATABASE .env | cut -d '=' -f2) < $(BACKUP_DIR)/database.sql
	@echo "Restoring media files..."
	tar -xzf $(BACKUP_DIR)/media.tar.gz -C volumes/magento/
	@echo "Restore completed!"

# Clean up
clean:
	@echo "Cleaning up Docker environment..."
	@echo "This will remove all containers, volumes, and images. Are you sure? [y/N]"
	@read -p " " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker-compose down -v --remove-orphans; \
		docker system prune -f; \
		docker volume prune -f; \
		echo "Cleanup completed!"; \
	else \
		echo "Cleanup cancelled."; \
	fi

# Show service status
status:
	@echo "Service status:"
	docker-compose ps

# Check service health
health:
	@echo "Checking service health..."
	@echo "Nginx: $(shell curl -s -o /dev/null -w "%{http_code}" http://localhost/health || echo "unreachable")"
	@echo "PHP-FPM: $(shell docker-compose exec php-fpm php -v | head -1 || echo "unreachable")"
	@echo "MariaDB: $(shell docker-compose exec mariadb mysqladmin ping -h localhost -u root -p$(shell grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2) 2>/dev/null && echo "healthy" || echo "unhealthy")"
	@echo "Redis: $(shell docker-compose exec redis redis-cli ping 2>/dev/null && echo "healthy" || echo "unhealthy")"
	@echo "OpenSearch: $(shell curl -s -o /dev/null -w "%{http_code}" http://localhost:9200/_cluster/health || echo "unreachable")"
	@echo "Varnish: $(shell curl -s -o /dev/null -w "%{http_code}" http://localhost:6081/ || echo "unreachable")"

# Update Magento and dependencies
update:
	@echo "Updating Magento and dependencies..."
	docker-compose exec php-fpm composer update
	docker-compose exec php-fpm php bin/magento setup:upgrade
	docker-compose exec php-fpm php bin/magento setup:di:compile
	docker-compose exec php-fpm php bin/magento setup:static-content:deploy -f
	docker-compose exec php-fpm php bin/magento cache:flush
	@echo "Update completed!"

# Setup development environment
setup-dev:
	@echo "Setting up development environment..."
	@echo "Enabling Xdebug..."
	@make xdebug-on
	@echo "Setting development mode..."
	docker-compose exec php-fpm php bin/magento deploy:mode:set developer
	@echo "Development environment setup completed!"

# Setup production environment
setup-prod:
	@echo "Setting up production environment..."
	@echo "Disabling Xdebug..."
	@make xdebug-off
	@echo "Setting production mode..."
	docker-compose exec php-fpm php bin/magento deploy:mode:set production
	@echo "Production environment setup completed!"

# Quick start for development
dev: up install setup-dev
	@echo "Development environment is ready!"
	@echo "Access your site at: http://localhost"
	@echo "Admin panel at: http://localhost/admin"
	@echo "Mailhog at: http://localhost:8025"
	@echo "RabbitMQ Management at: http://localhost:15672"
	@echo "OpenSearch at: http://localhost:9200"

# Quick start for production
prod: up install setup-prod
	@echo "Production environment is ready!"
	@echo "Access your site at: http://localhost"
	@echo "Admin panel at: http://localhost/admin"

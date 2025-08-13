# Magento 2.4.x Docker Environment

A complete, production-aligned Docker Compose environment for Magento 2.4.x that works for both local development and deployment to Coolify instances.

## 🚀 Features

- **PHP 8.3** with all required extensions for Magento 2.4.x
- **Nginx** web server with optimized configuration
- **Varnish 7.3** for full-page caching
- **OpenSearch 2.11.0** for search functionality
- **MariaDB 10.6** (LTS) for database
- **Redis 7.2** for caching and sessions
- **RabbitMQ 3.12** for message queuing
- **Mailhog** for email testing
- **Dedicated containers** for cron jobs and queue consumers
- **Persistent volumes** for data persistence
- **Production-ready** configurations with security best practices

## 📋 Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Make (optional, for using Makefile commands)
- Git

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Varnish      │    │     Nginx       │    │   PHP-FPM      │
│   (Port 6081)  │◄───┤   (Port 80)    │◄───┤   (Port 9000)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   OpenSearch   │    │     MariaDB     │    │     Redis      │
│   (Port 9200)  │    │   (Port 3306)   │    │   (Port 6379)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │    RabbitMQ     │
                       │   (Port 5672)   │
                       └─────────────────┘
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd m2-docker
```

### 2. Configure Environment

```bash
cp env.example .env
# Edit .env with your configuration
```

### 3. Start Services

```bash
# Using Makefile (recommended)
make up

# Or using Docker Compose directly
docker-compose up -d
```

### 4. Install Magento

```bash
# Using Makefile
make install

# Or manually
docker-compose exec php-fpm bash -c "cd /var/www/html && chmod +x scripts/m2-install.sh && ./scripts/m2-install.sh"
```

### 5. Access Your Site

- **Frontend**: http://localhost
- **Admin Panel**: http://localhost/admin
- **Mailhog**: http://localhost:8025
- **RabbitMQ Management**: http://localhost:15672
- **OpenSearch**: http://localhost:9200

## 🛠️ Available Commands

### Using Makefile

```bash
# Basic operations
make up              # Start all services
make down            # Stop all services
make restart         # Restart all services
make status          # Show service status
make health          # Check service health

# Magento operations
make install         # Install Magento
make reindex         # Reindex Magento
make cache-flush     # Flush cache
make cache-clean     # Clean cache
make update          # Update Magento

# Development
make xdebug-on       # Enable Xdebug
make xdebug-off      # Disable Xdebug
make setup-dev       # Setup development environment
make setup-prod      # Setup production environment

# Logs and debugging
make logs            # Show all logs
make logs-nginx      # Show Nginx logs
make logs-php        # Show PHP-FPM logs
make shell           # Open shell in PHP container

# Backup and maintenance
make backup          # Create backup
make restore         # Restore from backup
make clean           # Clean up environment
```

### Using Docker Compose Directly

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Execute commands
docker-compose exec php-fpm php bin/magento cache:flush
docker-compose exec mariadb mysql -u root -p
```

## ⚙️ Configuration

### Environment Variables

Key environment variables in `.env`:

```bash
# Application Settings
MAGENTO_VERSION=2.4.7
MAGENTO_MODE=production
MAGENTO_ADMIN_USER=admin
MAGENTO_ADMIN_PASSWORD=admin123
MAGENTO_ADMIN_EMAIL=admin@example.com

# Database
MYSQL_ROOT_PASSWORD=root123
MYSQL_DATABASE=magento
MYSQL_USER=magento
MYSQL_PASSWORD=magento123

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=

# OpenSearch
OPENSEARCH_HOST=opensearch
OPENSEARCH_USERNAME=admin
OPENSEARCH_PASSWORD=admin123

# RabbitMQ
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=admin123
```

### Service Configuration

- **Nginx**: `docker/nginx/default.conf`
- **Varnish**: `docker/varnish/default.vcl`
- **PHP**: `docker/php/php.ini` and `docker/php/php-fpm.conf`
- **MariaDB**: `docker/mariadb/my.cnf`

## 🔒 Security Features

- **Security headers** in Nginx configuration
- **File access restrictions** for sensitive directories
- **PHP security settings** (disabled dangerous functions)
- **MariaDB security** configurations
- **Container isolation** with proper networking

## 📊 Performance Optimizations

- **OPcache** enabled with optimized settings
- **APCu** for user cache
- **Redis** for sessions, cache, and page cache
- **Varnish** for full-page caching
- **MariaDB** optimized for Magento workloads
- **Static file caching** with proper headers

## 🐛 Development Features

- **Xdebug** support (can be enabled/disabled)
- **Development mode** support
- **Hot reload** for configuration changes
- **Comprehensive logging** for all services

## 🔄 Cron Jobs and Queue Consumers

### Cron Container
- Runs `bin/magento cron:run` every 60 seconds
- Dedicated container for reliability
- Automatic restart on failure

### Queue Consumer Container
- Listens to `async.operations.all` queue
- Configurable message limits
- Automatic restart on failure

## 💾 Data Persistence

Persistent volumes for:
- **MariaDB data**: `./volumes/mysql`
- **OpenSearch data**: `./volumes/opensearch`
- **Redis data**: `./volumes/redis`
- **RabbitMQ data**: `./volumes/rabbitmq`
- **Magento media**: `./volumes/magento/media`
- **Magento var**: `./volumes/magento/var`

## 🚀 Deployment

### Local Development
```bash
make dev
```

### Production Setup
```bash
make prod
```

### Coolify Deployment
See [Coolify Setup Guide](coolify-setup.md) for detailed instructions.

## 🧪 Testing

### Health Checks
```bash
make health
```

### Service Status
```bash
make status
```

### Log Monitoring
```bash
make logs
```

## 🔧 Troubleshooting

### Common Issues

1. **Services not starting**: Check Docker logs with `make logs`
2. **Permission issues**: Run `make shell` and check file ownership
3. **Database connection**: Verify MariaDB is running with `make status`
4. **Cache issues**: Use `make cache-flush` to clear all caches

### Debug Mode
```bash
# Enable Xdebug
make xdebug-on

# Set development mode
docker-compose exec php-fpm php bin/magento deploy:mode:set developer
```

## 📚 Additional Resources

- [Magento 2.4.x Documentation](https://devdocs.magento.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Coolify Documentation](https://coolify.io/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review service logs with `make logs`

---

**Note**: This environment is designed for production use but should be thoroughly tested in your specific environment before deployment.

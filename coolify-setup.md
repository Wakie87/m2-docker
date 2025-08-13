# Coolify Setup Guide for Magento 2.4.x Docker Environment

This guide provides step-by-step instructions for deploying your Magento 2.4.x Docker environment to Coolify, covering both development and production environments.

## 🎯 Overview

Coolify is a self-hosted platform-as-a-service that simplifies Docker deployments. This guide covers:

- **Development Environment**: Auto-deploy on push to development branch
- **Production Environment**: Manual deployment with approval workflow
- **Environment Variables & Secrets**: Secure configuration management
- **Persistent Volumes**: Data persistence across deployments
- **Wildcard SSL Domain Setup**: Leveraging `*.dev.fitchs.au` for multiple subdomains
- **Service-Specific Subdomains**: Dedicated domains for admin, API, media, and services
- **Backup Strategy**: Database and media file backups
- **Monitoring & Health Checks**: Service monitoring and alerts

## 🌟 **Wildcard SSL Benefits**

Your `*.dev.fitchs.au` wildcard SSL setup provides:

✅ **Automatic SSL for all subdomains** - No need to manage individual certificates  
✅ **Unlimited subdomain creation** - Easy to add new services and environments  
✅ **Zero SSL management overhead** - Coolify handles renewals automatically  
✅ **Professional domain structure** - Clean, organized service separation  
✅ **Cost-effective** - One certificate covers everything  
✅ **Security compliance** - HSTS, modern TLS protocols, security headers

## 🔧 **How Coolify + Traefik SSL Works**

When you deploy to Coolify, it automatically:

1. **Adds Traefik Labels**: Coolify injects Traefik labels into your Docker Compose
2. **SSL Termination**: Traefik handles all SSL/HTTPS traffic before it reaches your containers
3. **Certificate Management**: Automatic Let's Encrypt certificate generation and renewal
4. **HTTP Traffic Only**: Your Nginx container only needs to listen on port 80
5. **Automatic Routing**: Traefik routes traffic based on domain names to the correct containers

**Example Traefik labels Coolify adds**:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.m2-nginx.rule=Host(`m2-vgsco4o.dev.fitchs.au`)"
  - "traefik.http.routers.m2-nginx.tls=true"
  - "traefik.http.routers.m2-nginx.tls.certresolver=letsencrypt"
  - "traefik.http.services.m2-nginx.loadbalancer.server.port=80"
```

## 🪄 **Coolify Magic Environment Variables**

Coolify automatically generates dynamic environment variables for your services:

### **FQDN Variables** (Fully Qualified Domain Names)
- `SERVICE_FQDN_MAGENTO` → `m2-vgsco4o.dev.fitchs.au`
- `SERVICE_FQDN_ADMIN` → `admin-m2-vgsco4o.dev.fitchs.au`
- `SERVICE_FQDN_API` → `api-m2-vgsco4o.dev.fitchs.au`
- `SERVICE_FQDN_MEDIA` → `media-m2-vgsco4o.dev.fitchs.au`

### **URL Variables** (Full URLs with protocol)
- `SERVICE_URL_MAGENTO` → `https://m2-vgsco4o.dev.fitchs.au`
- `SERVICE_URL_RABBITMQ_MGMT` → `https://rabbitmq-m2-vgsco4o.dev.fitchs.au:15672`
- `SERVICE_URL_OPENSEARCH` → `https://opensearch-m2-vgsco4o.dev.fitchs.au:9200`

### **Security Variables** (Auto-generated)
- `SERVICE_PASSWORD_MAGENTO` → Random secure password
- `SERVICE_PASSWORD_MYSQL` → Random secure password
- `SERVICE_PASSWORD_REDIS` → Random secure password
- `SERVICE_BASE64_MAGENTO` → Random base64 string for encryption keys

### **Benefits of Magic Variables**:
✅ **Automatic Domain Generation** - No need to manually configure subdomains  
✅ **Secure Password Generation** - Unique, strong passwords for each service  
✅ **Dynamic URL Management** - URLs automatically update with environment changes  
✅ **Zero Configuration** - Coolify handles everything automatically  
✅ **Environment Isolation** - Each environment gets unique variables

## 🏗️ Prerequisites

- **Coolify Instance**: Self-hosted Coolify server running
- **Git Repository**: Your Magento 2.4.x Docker project in a Git repository
- **Domain Names**: Domain names for your environments (optional but recommended)
- **SSL Certificates**: Let's Encrypt or custom SSL certificates
- **Docker Registry**: Access to Docker Hub or private registry

## 📋 Coolify Project Setup

### 1. Create New Project

1. **Login to Coolify Dashboard**
2. **Click "New Project"**
3. **Select "Application"**
4. **Choose "Docker Compose"**
5. **Name**: `M2 Docker`
6. **Description**: `Magento 2.4.x Docker Environment`

### 2. Connect Git Repository

1. **Select your Git provider** (GitHub, GitLab, etc.)
2. **Choose your repository**
3. **Select branch**: `main` or `master`
4. **Set build pack**: `Docker Compose`

## 🚀 Development Environment Setup

### 1. Create Development Environment

1. **In your project, click "New Environment"**
2. **Environment Name**: `development`
3. **Branch**: `develop` or `development`
4. **Auto Deploy**: `Enabled`
5. **Build Pack**: `Docker Compose`

### 2. Configure Development Environment Variables

Set these environment variables in Coolify for your wildcard domain:

```bash
# Application Settings
MAGENTO_VERSION=2.4.7
MAGENTO_MODE=developer
MAGENTO_ADMIN_USER=admin
MAGENTO_ADMIN_PASSWORD=${SERVICE_PASSWORD_MAGENTO}
MAGENTO_ADMIN_EMAIL=admin@${SERVICE_FQDN_MAGENTO}
MAGENTO_ADMIN_FIRSTNAME=Admin
MAGENTO_ADMIN_LASTNAME=User

# Domain Configuration - Using Coolify's magic FQDN variables
MAGENTO_BASE_URL=${SERVICE_URL_MAGENTO}
MAGENTO_SECURE_BASE_URL=${SERVICE_URL_MAGENTO}
MAGENTO_BACKEND_NAME=admin

# Service Subdomains using magic variables (Coolify generates these automatically)
ADMIN_SUBDOMAIN=${SERVICE_FQDN_ADMIN}
API_SUBDOMAIN=${SERVICE_FQDN_API}
MEDIA_SUBDOMAIN=${SERVICE_FQDN_MEDIA}
STATIC_SUBDOMAIN=${SERVICE_FQDN_STATIC}
RABBITMQ_MANAGEMENT_URL=${SERVICE_URL_RABBITMQ_MGMT}
OPENSEARCH_URL=${SERVICE_URL_OPENSEARCH}
MAILHOG_URL=${SERVICE_URL_MAILHOG}

# Note: Coolify automatically generates:
# - SERVICE_FQDN_MAGENTO (e.g., dev-m2-vgsco4o.dev.fitchs.au)
# - SERVICE_PASSWORD_MAGENTO (secure random password)
# - SERVICE_BASE64_MAGENTO (encryption key)

# Database Configuration
MYSQL_ROOT_PASSWORD=${SERVICE_PASSWORD_MYSQL}
MYSQL_DATABASE=magento_dev
MYSQL_USER=magento_dev
MYSQL_PASSWORD=${SERVICE_PASSWORD_MYSQL}
MYSQL_HOST=mariadb
MYSQL_PORT=3306

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=${SERVICE_PASSWORD_REDIS}

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=${SERVICE_PASSWORD_RABBITMQ}
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672

# OpenSearch Configuration
OPENSEARCH_HOST=opensearch
OPENSEARCH_PORT=9200
OPENSEARCH_USERNAME=admin
OPENSEARCH_PASSWORD=${SERVICE_PASSWORD_OPENSEARCH}

# Varnish Configuration
VARNISH_HOST=varnish
VARNISH_PORT=80
VARNISH_BACKEND_HOST=nginx
VARNISH_BACKEND_PORT=80

# Development Settings
XDEBUG_ENABLED=true
XDEBUG_HOST=host.docker.internal
XDEBUG_PORT=9003

# Resource Limits (Development - Lower)
NGINX_MEMORY_LIMIT=128M
PHP_MEMORY_LIMIT_CONTAINER=512M
MARIADB_MEMORY_LIMIT=512M
OPENSEARCH_MEMORY_LIMIT=1G
REDIS_MEMORY_LIMIT=128M
RABBITMQ_MEMORY_LIMIT=256M
VARNISH_MEMORY_LIMIT=256M
```

### 3. Development Environment Secrets

Set these as secrets in Coolify:

```bash
# Composer Authentication (if using private packages)
COMPOSER_AUTH_USERNAME=your_composer_username
COMPOSER_AUTH_PASSWORD=your_composer_token

# Magento Encryption Key (generate unique for dev)
MAGENTO_ENCRYPTION_KEY=your_dev_encryption_key_here
```

### 4. Development Environment Configuration

1. **Port Configuration**: Use default ports (80, 443, 3306, etc.)
2. **Health Check Path**: `/health`
3. **Build Command**: Leave empty (uses Docker Compose)
4. **Start Command**: Leave empty (uses Docker Compose)

## 🏭 Production Environment Setup

### 1. Create Production Environment

1. **In your project, click "New Environment"**
2. **Environment Name**: `production`
3. **Branch**: `main` or `master`
4. **Auto Deploy**: `Disabled` (manual deployment)
5. **Build Pack**: `Docker Compose`
6. **Require Approval**: `Enabled`

### 2. Configure Production Environment Variables

Set these environment variables in Coolify for your wildcard domain:

```bash
# Application Settings
MAGENTO_VERSION=2.4.7
MAGENTO_MODE=production
MAGENTO_ADMIN_USER=admin
MAGENTO_ADMIN_PASSWORD=${SERVICE_PASSWORD_MAGENTO}
MAGENTO_ADMIN_EMAIL=admin@${SERVICE_FQDN_MAGENTO}
MAGENTO_ADMIN_FIRSTNAME=Admin
MAGENTO_ADMIN_LASTNAME=User

# Domain Configuration - Using Coolify's magic FQDN variables
MAGENTO_BASE_URL=${SERVICE_URL_MAGENTO}
MAGENTO_SECURE_BASE_URL=${SERVICE_URL_MAGENTO}
MAGENTO_BACKEND_NAME=admin

# Service Subdomains using magic variables (Coolify generates these automatically)
ADMIN_SUBDOMAIN=${SERVICE_FQDN_ADMIN}
API_SUBDOMAIN=${SERVICE_FQDN_API}
MEDIA_SUBDOMAIN=${SERVICE_FQDN_MEDIA}
STATIC_SUBDOMAIN=${SERVICE_FQDN_STATIC}
RABBITMQ_MANAGEMENT_URL=${SERVICE_URL_RABBITMQ_MGMT}
OPENSEARCH_URL=${SERVICE_URL_OPENSEARCH}
MAILHOG_URL=${SERVICE_URL_MAILHOG}

# Note: Coolify automatically generates:
# - SERVICE_FQDN_MAGENTO (e.g., m2-vgsco4o.dev.fitchs.au)
# - SERVICE_PASSWORD_MAGENTO (secure random password)
# - SERVICE_BASE64_MAGENTO (encryption key)

# Database Configuration
MYSQL_ROOT_PASSWORD=${SERVICE_PASSWORD_MYSQL}
MYSQL_DATABASE=magento_prod
MYSQL_USER=magento_prod
MYSQL_PASSWORD=${SERVICE_PASSWORD_MYSQL}
MYSQL_HOST=mariadb
MYSQL_PORT=3306

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=${SERVICE_PASSWORD_REDIS}

# RabbitMQ Configuration
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=${SERVICE_PASSWORD_RABBITMQ}
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672

# OpenSearch Configuration
OPENSEARCH_HOST=opensearch
OPENSEARCH_PORT=9200
OPENSEARCH_USERNAME=admin
OPENSEARCH_PASSWORD=${SERVICE_PASSWORD_OPENSEARCH}

# Varnish Configuration
VARNISH_HOST=varnish
VARNISH_PORT=80
VARNISH_BACKEND_HOST=nginx
VARNISH_BACKEND_PORT=80

# Production Settings
XDEBUG_ENABLED=false

# Resource Limits (Production - Higher)
NGINX_MEMORY_LIMIT=256M
PHP_MEMORY_LIMIT_CONTAINER=1G
MARIADB_MEMORY_LIMIT=2G
OPENSEARCH_MEMORY_LIMIT=4G
REDIS_MEMORY_LIMIT=512M
RABBITMQ_MEMORY_LIMIT=1G
VARNISH_MEMORY_LIMIT=1G

# Security
QUEUE_CONSUMER_MAX_MESSAGES=1000
```

### 3. Production Environment Secrets

Set these as secrets in Coolify:

```bash
# Composer Authentication
COMPOSER_AUTH_USERNAME=your_composer_username
COMPOSER_AUTH_PASSWORD=your_composer_token

# Magento Encryption Key (generate unique for production)
MAGENTO_ENCRYPTION_KEY=your_prod_encryption_key_here

# Database Backup Credentials
DB_BACKUP_USER=backup_user
DB_BACKUP_PASSWORD=backup_password

# Redis Password
REDIS_PASSWORD=prod_redis123
```

## 🔐 Environment Variables & Secrets Management

### 1. Environment Variables vs Secrets

**Environment Variables** (public):
- Configuration settings
- Non-sensitive data
- Build-time configurations

**Secrets** (private):
- Passwords and tokens
- API keys
- Encryption keys
- Database credentials

### 2. Coolify Magic Variables Integration

**How to Use Magic Variables in Docker Compose**:

```yaml
services:
  nginx:
    environment:
      # Coolify will automatically generate these values
      - MAGENTO_BASE_URL=${SERVICE_URL_MAGENTO}
      - MAGENTO_ADMIN_PASSWORD=${SERVICE_PASSWORD_MAGENTO}
      - MAGENTO_ENCRYPTION_KEY=${SERVICE_BASE64_MAGENTO}
  
  mariadb:
    environment:
      - MYSQL_ROOT_PASSWORD=${SERVICE_PASSWORD_MYSQL}
      - MYSQL_PASSWORD=${SERVICE_PASSWORD_MYSQL}
  
  redis:
    command: redis-server --requirepass ${SERVICE_PASSWORD_REDIS}
  
  rabbitmq:
    environment:
      - RABBITMQ_DEFAULT_PASS=${SERVICE_PASSWORD_RABBITMQ}
  
  opensearch:
    environment:
      - OPENSEARCH_INITIAL_ADMIN_PASSWORD=${SERVICE_PASSWORD_OPENSEARCH}
```

**Magic Variable Types Available**:
- **FQDN**: `SERVICE_FQDN_<SERVICE>` - Domain names
- **URL**: `SERVICE_URL_<SERVICE>` - Full URLs with protocol
- **PASSWORD**: `SERVICE_PASSWORD_<SERVICE>` - Secure passwords
- **BASE64**: `SERVICE_BASE64_<SERVICE>` - Random base64 strings
- **USER**: `SERVICE_USER_<SERVICE>` - Random usernames

### 2. Setting Environment Variables

1. **Go to Environment Settings**
2. **Click "Environment Variables"**
3. **Add each variable** with key-value pairs
4. **Set scope** (Build, Runtime, or Both)

### 3. Setting Secrets

1. **Go to Environment Settings**
2. **Click "Secrets"**
3. **Add each secret** with key-value pairs
4. **Secrets are encrypted** and never logged

### 4. Environment-Specific Variables

Use Coolify's environment variable inheritance:
- **Global**: Set at project level
- **Environment-specific**: Override global values
- **Build vs Runtime**: Different variables for different phases

## 💾 Persistent Volumes Setup

### 1. Volume Configuration

Coolify automatically creates persistent volumes for:

```yaml
volumes:
  mysql_data:
    driver: local
  opensearch_data:
    driver: local
  redis_data:
    driver: local
  rabbitmq_data:
    driver: local
  magento_media:
    driver: local
  magento_var:
    driver: local
```

### 2. Volume Backup Strategy

1. **Database Backups**:
   - Automated daily backups
   - Retention: 30 days
   - Backup location: Coolify managed storage

2. **Media File Backups**:
   - Weekly backups
   - Retention: 90 days
   - Backup location: Coolify managed storage

### 3. Volume Management

1. **Volume Size Monitoring**: Monitor volume usage in Coolify dashboard
2. **Volume Expansion**: Coolify can expand volumes as needed
3. **Volume Migration**: Easy migration between Coolify instances

## 🌐 Wildcard SSL Domain Setup (*.dev.fitchs.au)

### 1. Domain Configuration

With your self-hosted Coolify and wildcard SSL for `*.dev.fitchs.au`, you can create multiple subdomains:

**Main Application Domains**:
- **Production**: `m2.dev.fitchs.au`
- **Development**: `dev.m2.dev.fitchs.au`
- **Staging**: `staging.m2.dev.fitchs.au`

**Service-Specific Subdomains**:
- **Admin Panel**: `admin.m2.dev.fitchs.au`
- **API Endpoints**: `api.m2.dev.fitchs.au`
- **Media Files**: `media.m2.dev.fitchs.au`
- **Static Assets**: `static.m2.dev.fitchs.au`
- **RabbitMQ Management**: `rabbitmq.m2.dev.fitchs.au`
- **OpenSearch**: `opensearch.m2.dev.fitchs.au`
- **MailHog**: `mail.m2.dev.fitchs.au`

### 2. DNS Configuration

1. **Wildcard DNS Record**:
   ```
   *.dev.fitchs.au → Your Coolify Server IP
   ```

2. **Specific Subdomain Records** (optional, for explicit control):
   ```
   m2.dev.fitchs.au → Your Coolify Server IP
   admin.m2.dev.fitchs.au → Your Coolify Server IP
   api.m2.dev.fitchs.au → Your Coolify Server IP
   ```

### 3. SSL Certificate Setup

**Wildcard SSL Certificate** (Managed by Coolify + Traefik):
- **Domain**: `*.dev.fitchs.au`
- **Provider**: Let's Encrypt (via Coolify's Traefik)
- **Auto-renewal**: Every 90 days (automatic)
- **Coverage**: All subdomains automatically secured
- **Management**: Coolify handles everything - no manual configuration needed

**How it works**:
- Coolify automatically adds Traefik labels to your Docker Compose
- Traefik handles SSL termination and certificate management
- Nginx only processes HTTP traffic (port 80)
- All SSL/HTTPS traffic is handled by Traefik before reaching Nginx

### 3. TLS Configuration

1. **Force HTTPS**: Redirect HTTP to HTTPS
2. **HSTS**: Enable HTTP Strict Transport Security
3. **TLS Version**: Minimum TLS 1.2, prefer TLS 1.3

## 🚀 First Deploy & Installation

### 1. Initial Deployment

1. **Deploy Environment**: Click "Deploy" in Coolify
2. **Monitor Build**: Watch build logs for any issues
3. **Wait for Services**: All containers must be healthy

### 2. Wildcard Domain Verification

After deployment, verify your subdomains are working:

```bash
# Main application (using magic variable)
curl -I ${SERVICE_URL_MAGENTO}

# Admin panel (using magic variable)
curl -I ${SERVICE_URL_ADMIN}

# API endpoints (using magic variable)
curl -I ${SERVICE_URL_API}

# Service management (using magic variables)
curl -I ${SERVICE_URL_RABBITMQ_MGMT}
curl -I ${SERVICE_URL_OPENSEARCH}
curl -I ${SERVICE_URL_MAILHOG}
```

**Example of Generated URLs** (Coolify will create these automatically):
```bash
# If your app UUID is 'vgsco4o', Coolify generates:
SERVICE_URL_MAGENTO=https://m2-vgsco4o.dev.fitchs.au
SERVICE_URL_ADMIN=https://admin-m2-vgsco4o.dev.fitchs.au
SERVICE_URL_API=https://api-m2-vgsco4o.dev.fitchs.au
SERVICE_URL_RABBITMQ_MGMT=https://rabbitmq-m2-vgsco4o.dev.fitchs.au:15672
SERVICE_URL_OPENSEARCH=https://opensearch-m2-vgsco4o.dev.fitchs.au:9200
SERVICE_URL_MAILHOG=https://mail-m2-vgsco4o.dev.fitchs.au:8025
```

### 3. SSL Certificate Verification

Check that SSL is working correctly:

```bash
# Verify certificate details
openssl s_client -connect m2.dev.fitchs.au:443 -servername m2.dev.fitchs.au

# Check certificate expiration
echo | openssl s_client -servername m2.dev.fitchs.au -connect m2.dev.fitchs.au:443 2>/dev/null | openssl x509 -noout -dates
```

### 2. Magento Installation

After successful deployment, run the installation script:

```bash
# Connect to PHP container
coolify exec -e production php-fpm

# Run installation script
cd /var/www/html
chmod +x scripts/m2-install.sh
./scripts/m2-install.sh
```

### 3. Post-Installation Setup

1. **Verify Installation**:
   - Check frontend: `https://yourdomain.com`
   - Check admin: `https://yourdomain.com/admin`
   - Verify all services are running

2. **Configure Cron Jobs**:
   - Cron container runs automatically
   - Verify in Magento admin: System > Tools > Cron

3. **Configure Queue Consumers**:
   - Queue consumer container runs automatically
   - Monitor in RabbitMQ management: `https://yourdomain.com:15672`

## 🔄 Deployment Workflow

### 1. Development Workflow

```bash
# 1. Make changes in development branch
git checkout develop
git add .
git commit -m "Feature: Add new functionality"
git push origin develop

# 2. Coolify automatically deploys
# 3. Monitor deployment in Coolify dashboard
# 4. Test changes on development environment
```

### 2. Production Workflow

```bash
# 1. Merge development to main
git checkout main
git merge develop
git push origin main

# 2. Manual deployment in Coolify
# 3. Review and approve deployment
# 4. Monitor production deployment
# 5. Verify functionality
```

### 3. Rollback Strategy

1. **Quick Rollback**: Use Coolify's rollback feature
2. **Database Rollback**: Restore from backup if needed
3. **Code Rollback**: Deploy previous commit

## 📊 Monitoring & Health Checks

### 1. Health Check Configuration

```yaml
# In docker-compose.yml
services:
  nginx:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 2. Monitoring Endpoints

- **Nginx Health**: `/health`
- **PHP-FPM Status**: `/status` (if enabled)
- **MariaDB**: Connection test
- **Redis**: PING command
- **OpenSearch**: `/_cluster/health`

### 3. Alerting

1. **Service Down**: Email/Slack notifications
2. **High Resource Usage**: CPU/Memory alerts
3. **Disk Space**: Volume usage alerts
4. **SSL Expiry**: Certificate expiration warnings

## 🔒 Security Recommendations

### 1. Network Security

1. **Firewall Rules**: Restrict access to necessary ports only
2. **VPC/Private Network**: Use private networking if available
3. **Load Balancer**: Implement WAF and DDoS protection

### 2. Container Security

1. **Image Scanning**: Regular vulnerability scans
2. **Non-root Users**: All containers run as non-root
3. **Resource Limits**: Prevent resource exhaustion attacks

### 3. Application Security

1. **Admin URL**: Use custom admin path
2. **Two-Factor Authentication**: Enable for admin users
3. **Regular Updates**: Keep Magento and dependencies updated

## 💾 Backup Strategy

### 1. Automated Backups

1. **Database Backups**:
   - Frequency: Daily at 2 AM
   - Retention: 30 days
   - Compression: Gzip
   - Verification: Checksum validation

2. **Media Backups**:
   - Frequency: Weekly on Sundays
   - Retention: 90 days
   - Compression: Tar.gz
   - Verification: File integrity checks

### 2. Manual Backups

```bash
# Database backup
coolify exec -e production mariadb
mysqldump -u root -p magento_prod > backup.sql

# Media backup
tar -czf media_backup.tar.gz volumes/magento/media/
```

### 3. Backup Storage

1. **Local Storage**: Coolify managed volumes
2. **Remote Storage**: S3-compatible storage
3. **Offsite Backup**: Secondary location for disaster recovery

## 🔄 Queue Consumers & Cron Jobs

### 1. Queue Consumer Management

1. **Automatic Start**: Container starts automatically
2. **Health Monitoring**: Coolify monitors container health
3. **Log Monitoring**: Track consumer performance
4. **Scaling**: Add more consumer containers if needed

### 2. Cron Job Management

1. **Automatic Execution**: Runs every 60 seconds
2. **Log Monitoring**: Track cron execution
3. **Error Handling**: Automatic retry on failure
4. **Performance Monitoring**: Track execution time

### 3. Monitoring Commands

```bash
# Check queue status
coolify exec -e production php-fpm
php bin/magento queue:consumers:list

# Check cron status
php bin/magento cron:run

# View queue messages
php bin/magento queue:consumers:start async.operations.all --max-messages=1
```

## 📈 Resource Limits & Scaling

### 1. Resource Allocation

**Development Environment**:
- CPU: 1-2 cores per container
- Memory: 512M-1G per container
- Storage: 10-20GB per volume

**Production Environment**:
- CPU: 2-4 cores per container
- Memory: 1-4G per container
- Storage: 50-100GB per volume

### 2. Scaling Strategies

1. **Horizontal Scaling**: Add more containers
2. **Vertical Scaling**: Increase container resources
3. **Load Balancing**: Distribute traffic across containers

### 3. Resource Monitoring

1. **CPU Usage**: Monitor per-container CPU usage
2. **Memory Usage**: Track memory consumption
3. **Disk I/O**: Monitor storage performance
4. **Network I/O**: Track network usage

## 🚨 Troubleshooting

### 1. Common Issues

**Services Not Starting**:
1. Check Coolify logs
2. Verify environment variables
3. Check resource limits
4. Verify Docker images

**Database Connection Issues**:
1. Check MariaDB container status
2. Verify database credentials
3. Check network connectivity
4. Verify volume permissions

**Performance Issues**:
1. Monitor resource usage
2. Check cache configuration
3. Verify indexing status
4. Monitor queue processing

### 2. Debug Commands

```bash
# Check container status
coolify ps -e production

# View logs
coolify logs -e production

# Execute commands
coolify exec -e production php-fpm php bin/magento cache:status

# Check volumes
coolify volume ls
```

### 3. Support Resources

1. **Coolify Documentation**: https://coolify.io/docs
2. **Magento Documentation**: https://devdocs.magento.com/
3. **Docker Documentation**: https://docs.docker.com/
4. **Community Forums**: Coolify and Magento communities

## 📋 Checklist

### Pre-Deployment
- [ ] Git repository configured
- [ ] Coolify project created
- [ ] Environment variables set
- [ ] Secrets configured
- [ ] Domain names configured
- [ ] SSL certificates ready

### Development Environment
- [ ] Environment created
- [ ] Auto-deploy enabled
- [ ] Variables configured
- [ ] First deployment successful
- [ ] Magento installed
- [ ] Health checks passing

### Production Environment
- [ ] Environment created
- [ ] Manual deployment enabled
- [ ] Approval workflow configured
- [ ] Variables configured
- [ ] First deployment successful
- [ ] Magento installed
- [ ] SSL configured
- [ ] Monitoring enabled

### Post-Deployment
- [ ] Cron jobs running
- [ ] Queue consumers active
- [ ] Backups configured
- [ ] Monitoring alerts set
- [ ] Performance optimized
- [ ] Security hardened

## 🎉 Conclusion

This setup provides a robust, scalable, and secure Magento 2.4.x environment on Coolify. The separation of development and production environments ensures proper testing and deployment workflows, while the comprehensive monitoring and backup strategies ensure reliability and data safety.

Remember to:
- Regularly update Magento and dependencies
- Monitor resource usage and performance
- Test backup and restore procedures
- Keep security configurations up to date
- Monitor logs and alerts proactively

For additional support or questions, refer to the Coolify and Magento documentation, or reach out to the respective communities.

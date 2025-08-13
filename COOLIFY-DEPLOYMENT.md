# Coolify Deployment Guide

This Magento 2 Docker setup is now simplified for easy deployment on Coolify using proven pre-built images.

## What Changed

- ✅ Removed custom PHP Dockerfile (was causing build failures)
- ✅ Using official `php:8.3-fpm` image (stable and tested)
- ✅ Updated to stable versions of all services
- ✅ Fixed circular dependency between nginx and varnish
- ✅ **Removed custom networks** (Coolify handles networking automatically)
- ✅ **Split Redis into two services**: cache and sessions
- ✅ **Fixed volume mounts** using named volumes instead of environment variables
- ✅ Based on proven MagenX approach

## Image Versions (Stable & Tested)

- **PHP-FPM**: `php:8.3-fpm` (official image)
- **MariaDB**: `mariadb:10.5` (stable version)
- **Redis Cache**: `redis:7.0-alpine` (Port 6379)
- **Redis Sessions**: `redis:7.0-alpine` (Port 6380)
- **OpenSearch**: `opensearchproject/opensearch:2.9.0` (stable version)
- **RabbitMQ**: `rabbitmq:3.11-management-alpine` (stable version)
- **Varnish**: `varnish:7.2-alpine` (stable version)
- **Nginx**: `nginx:1.25-alpine` (latest stable)

## Coolify Setup

1. **Import Repository**: Point Coolify to this repository
2. **Environment Variables**: Coolify will automatically generate:
   - `SERVICE_PASSWORD_MYSQL` - Database password
   - `SERVICE_PASSWORD_REDIS_CACHE` - Redis cache password
   - `SERVICE_PASSWORD_REDIS_SESSIONS` - Redis sessions password
   - `SERVICE_PASSWORD_RABBITMQ` - RabbitMQ password
   - `SERVICE_PASSWORD_OPENSEARCH` - OpenSearch password
   - `SERVICE_FQDN_MAGENTO` - Your domain

3. **Deploy**: Coolify will now use stable pre-built images

## Architecture

```
Internet → Varnish (Port 6081) → Nginx (Port 80/443) → PHP-FPM → MariaDB/Redis Cache/Redis Sessions/RabbitMQ/OpenSearch
```

## Services

- **Nginx**: Web server (Port 80/443)
- **PHP-FPM**: PHP processing (Port 9000)
- **Varnish**: Cache layer (Port 6081)
- **MariaDB**: Database (Port 3306)
- **Redis Cache**: Cache storage (Port 6379)
- **Redis Sessions**: Session storage (Port 6380)
- **RabbitMQ**: Message queue (Port 5672, Management 15672)
- **OpenSearch**: Search engine (Port 9200)
- **Mailhog**: Email testing (Port 1025, Web 8025)

## Redis Split Benefits

- **Better Performance**: Cache and sessions don't compete for memory
- **Isolation**: Cache corruption won't affect sessions
- **Scalability**: Can scale cache and sessions independently
- **Magento Best Practice**: Follows official Magento 2 recommendations

## Local Development

For local development, you can still use:
```bash
docker-compose up -d
```

## Coolify Benefits

- ✅ Automatic SSL certificates via Traefik
- ✅ No manual certificate management needed
- ✅ Stable pre-built images = reliable deployments
- ✅ Automatic environment variable generation
- ✅ **No custom networks needed** - Coolify handles everything
- ✅ **Proper volume management** - no more mount path errors
- ✅ Based on proven MagenX configuration approach

## Why These Versions?

These versions are chosen because they:
- Are stable and well-tested
- Have good compatibility with Magento 2.4.x
- Are widely used in production
- Have minimal breaking changes
- Follow the same approach as the successful [MagenX configuration](https://github.com/magenx/Magento-2-docker-configuration)

## Volume Management

All services now use named volumes managed by Coolify:
- `mysql_data` - MariaDB data
- `opensearch_data` - OpenSearch data
- `redis_cache_data` - Redis cache data
- `redis_sessions_data` - Redis sessions data
- `rabbitmq_data` - RabbitMQ data

This eliminates the environment variable substitution issues that were causing mount path errors.

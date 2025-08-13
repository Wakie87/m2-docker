FROM php:8.3-fpm

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_MEMORY_LIMIT=2G
ENV PHP_MAX_EXECUTION_TIME=1800
ENV PHP_UPLOAD_MAX_FILESIZE=64M
ENV PHP_POST_MAX_SIZE=64M

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libicu-dev \
    libmcrypt-dev \
    libmagickwand-dev \
    libgmp-dev \
    libssl-dev \
    libsodium-dev \
    libbz2-dev \
    libreadline-dev \
    libedit-dev \
    libsqlite3-dev \
    libxslt-dev \
    libgd-dev \
    libtidy-dev \
    libonig-dev \
    libzip-dev \
    unzip \
    zip \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-configure intl \
    && docker-php-ext-configure zip \
    && docker-php-ext-configure opcache --enable-opcache

RUN docker-php-ext-install \
    bcmath \
    bz2 \
    calendar \
    exif \
    gd \
    gettext \
    gmp \
    intl \
    mbstring \
    mysqli \
    opcache \
    pdo_mysql \
    soap \
    sockets \
    tidy \
    xsl \
    zip

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Imagick extension
RUN pecl install imagick && docker-php-ext-enable imagick

# Install APCu extension
RUN pecl install apcu && docker-php-ext-enable apcu

# Install Xdebug (for development)
ARG XDEBUG_ENABLED=false
ARG XDEBUG_HOST=host.docker.internal
ARG XDEBUG_PORT=9003

RUN if [ "$XDEBUG_ENABLED" = "true" ]; then \
        pecl install xdebug && \
        docker-php-ext-enable xdebug && \
        echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
        echo "xdebug.client_host=$XDEBUG_HOST" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
        echo "xdebug.client_port=$XDEBUG_PORT" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
        echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    fi

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create magento user
RUN useradd -m -s /bin/bash magento && \
    usermod -a -G www-data magento

# Set working directory
WORKDIR /var/www/html

# Copy PHP configuration files
COPY php.ini /usr/local/etc/php/
COPY php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Set permissions
RUN chown -R magento:magento /var/www/html && \
    chmod -R 755 /var/www/html

# Switch to magento user
USER magento

# Expose port 9000
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]

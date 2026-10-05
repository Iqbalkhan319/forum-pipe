# Use PHP 7.4 with FPM (Debian 11 "Bullseye" base, now end-of-life)
FROM php:7.4-fpm

# Set working directory
WORKDIR /var/www

# Bullseye is EOL: deb.debian.org no longer serves its security packages.
# Point apt at the frozen Debian snapshot taken just after end of support.
RUN printf '%s\n' \
      'deb http://snapshot.debian.org/archive/debian/20260901T000000Z bullseye main' \
      'deb http://snapshot.debian.org/archive/debian/20260901T000000Z bullseye-updates main' \
      'deb http://snapshot.debian.org/archive/debian-security/20260901T000000Z bullseye-security main' \
      > /etc/apt/sources.list \
    && rm -f /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources \
    && printf '%s\n' \
      'Acquire::Check-Valid-Until "false";' \
      'Acquire::Retries "5";' \
      > /etc/apt/apt.conf.d/99eol-snapshot

# Install required dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    libonig-dev \
    netcat-openbsd \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd mbstring pdo pdo_mysql opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy application files
COPY . /var/www

# Install PHP dependencies and optimise autoloader
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Set correct permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Copy and set up the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose PHP-FPM port
EXPOSE 9000

# Use custom entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Start PHP-FPM as the main process
CMD ["php-fpm"]

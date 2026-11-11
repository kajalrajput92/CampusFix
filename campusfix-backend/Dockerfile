FROM php:8.3-cli-alpine

# Install required system libraries and PHP extensions
RUN apk add --no-cache \
    git \
    unzip \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql gd fileinfo

# Copy Composer binary
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy backend files
COPY . /app/

# Install production dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Create and grant permissions on storage directory
RUN mkdir -p /app/storage/uploads/complaints && chmod -R 777 /app/storage

ENV PORT=10000
EXPOSE 10000

CMD sh -c "php -S 0.0.0.0:\${PORT:-10000} -t public public/index.php"

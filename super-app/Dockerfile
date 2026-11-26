FROM php:8.2-fpm

# Ekstensi PHP yang dibutuhkan super-app (Laravel 12):
# pdo_mysql, mbstring, xml, bcmath, zip, gd, intl, pcntl, imagick, redis.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git unzip zip \
      libzip-dev libicu-dev libxml2-dev libonig-dev \
      libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
      libmagickwand-dev pkg-config \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" \
      pdo_mysql mbstring xml bcmath zip gd intl pcntl \
 && pecl install imagick redis \
 && docker-php-ext-enable imagick redis \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]

# php:8.2-fpm default: "listen = 9000" hanya bind IPv6 ([::]:9000).
# nginx-resolve "super-app" menghasilkan IPv4, jadi override ke semua IPv4.
RUN printf '[www]\nlisten = 0.0.0.0:9000\n' > /usr/local/etc/php-fpm.d/zz-hms-listen.conf

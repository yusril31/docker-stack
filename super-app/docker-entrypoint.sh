#!/bin/sh
set -e

cd /var/www/html

# Pasang dependensi bila vendor belum ada di source yang di-mount.
if [ ! -d vendor ]; then
  composer install --no-interaction --prefer-dist --no-progress
fi

# Laravel butuh storage dan bootstrap/cache writable oleh PHP-FPM (www-data).
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
php artisan storage:link >/dev/null 2>&1 || true

exec "$@"

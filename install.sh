#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker belum terpasang. Install dulu: https://docs.docker.com/engine/install/"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Plugin 'docker compose' belum ada."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Tidak bisa mengakses Docker daemon. Pastikan user sudah di grup 'docker':"
  echo "  sudo usermod -aG docker \$USER   # lalu logout/login ulang"
  exit 1
fi

rand() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 16
  else
    head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n'
  fi
}

if [ ! -f .env ]; then
  cat > .env <<EOF
# Dibuat otomatis oleh install.sh pada $(date -Iseconds)
MYSQL_ROOT_PASSWORD=$(rand)
MYSQL_DATABASE=app
MYSQL_USER=app
MYSQL_PASSWORD=$(rand)
REDIS_PASSWORD=$(rand)
MONGO_ROOT_USERNAME=root
MONGO_ROOT_PASSWORD=$(rand)
EOF
  echo ".env dibuat dengan password acak: $PWD/.env"
fi

export SUPER_APP_PATH="${SUPER_APP_PATH:-/var/www/super-app}"
if [ ! -d "$SUPER_APP_PATH" ]; then
  echo "Catatan: SUPER_APP_PATH=$SUPER_APP_PATH belum ada."
  echo "        Set SUPER_APP_PATH ke lokasi repo super-app."
fi

docker compose up -d

echo
echo "Nginx      : http://<ip-host>:8081        (PHP: /index.php)"
echo "Super-app  : http://<ip-host>:8083        (repo: $SUPER_APP_PATH)"
echo "Node       : http://<ip-host>:3000"
echo "MySQL      : <ip-host>:3306   db=app user=app"
echo "Redis      : <ip-host>:6380"
echo "MongoDB    : <ip-host>:27017"
echo "Hermes     : docker exec -it hermes-agent hermes setup --portal"
echo "Logs       : docker compose logs -f"
echo "Kredensial : lihat $PWD/.env"

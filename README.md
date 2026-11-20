# Docker Stack: Nginx + PHP 8.2 + Node 26 + MySQL + Redis + MongoDB + Hermes + Super App

Paket portabel untuk menjalankan web server full-stack, HMS Super App (Laravel),
dan Hermes Agent di satu host Ubuntu.

## Isi

- `docker-compose.yaml` — service: `nginx`, `php`, `node`, `mysql`, `redis`,
  `mongodb`, `super-app`, `super-app-queue`, `nginx-super-app`, `hermes-agent`.
- `nginx/default.conf` — vhost Nginx (statis + PHP-FPM via service `php:9000`).
- `nginx/super-app.conf` — vhost Laravel (root `public`, PHP-FPM via `super-app:9000`).
- `html/` — dokumen web yang dipakai Nginx dan PHP (`index.php`, `index.html`).
- `app/` — contoh app Node.js (`node:26-bookworm`) yang listen di port 3000.
- `super-app/` — Dockerfile PHP 8.2 + entrypoint untuk HMS Super App.
- `install.sh` — cek prasyarat, membuat `.env` (password acak), `up -d`.
- `.env.example` — contoh variabel (opsional; `install.sh` membuat `.env`).

## Langkah install di komputer baru

```bash
# 1. Pasang Docker (sekali saja di host)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# logout, lalu login ulang

# 2. Salin folder ini ke komputer baru, lalu:
export SUPER_APP_PATH=/path/ke/repo/super-app   # default /var/www/super-app
./install.sh
```

## Port

| Service            | Host port | Catatan                                                  |
|--------------------|-----------|----------------------------------------------------------|
| Nginx              | 8081      | ganti ke `80:80` bila port 80 bebas                      |
| Node               | 3000      |                                                          |
| MySQL              | 3306      | db `app`, user `app`                                     |
| Redis              | 6380      | host 6379 biasanya dipakai Redis bawaan                  |
| MongoDB            | 27017     | user `root`                                              |
| Super App (Nginx)  | 8083      | Laravel 12; repo via `SUPER_APP_PATH`                    |
| Hermes             | 8642      | gateway API (API server default mati)                    |

Kredensial database ada di `.env` (dibuat acak oleh `install.sh`).

## Setelah jalan

```bash
curl http://localhost:8081/           # Nginx/PHP
curl http://localhost:3000/           # Node
curl http://localhost:8083/           # Super App (Laravel)
docker compose ps
docker compose logs -f
```

## Super App (Laravel 12)

- Image `hms/super-app:8.2` dibangun dari `super-app/Dockerfile`: PHP 8.2-FPM
  dengan ekstensi `pdo_mysql`, `mbstring`, `xml`, `bcmath`, `zip`, `gd`,
  `intl`, `pcntl`, `imagick`, `redis`, plus Composer.
- Source repo di-mount ke `/var/www/html` (path dari `SUPER_APP_PATH`).
  `vendor` dipasang otomatis bila belum ada; `storage`/`bootstrap/cache`
  di-`chown` ke `www-data`; `storage:link` dibuat oleh entrypoint.
- **DB tetap eksternal**: `.env` super-app mengarah ke
  `192.168.50.5:33066` untuk semua koneksi modul. Pastikan host bisa menjangkau
  alamat itu dari container (di WSL2/Ubuntu biasanya bisa).
- **Redis**: service `redis` di stack ini dipakai untuk cache + queue
  (`REDIS_HOST=redis`, password dari `.env` stack).
- **Queue worker**: service `super-app-queue` menjalankan
  `php artisan queue:work`.
- **Scheduler** (opsional): tambahkan service dengan
  `command: ["php", "artisan", "schedule:work"]` bila memakai cron Laravel.
- Untuk produksi, set `APP_ENV=production` dan `APP_DEBUG=false` di `.env`
  super-app (jangan debug terbuka ke publik).

### Verifikasi

```bash
curl -I http://localhost:8083/                 # halaman login/redirect Laravel
docker compose logs super-app-queue            # worker berjalan
```

## Volume

| Volume Compose                  | Mount di container | Isi                     |
|---------------------------------|--------------------|-------------------------|
| `docker-stack_hermes_data`      | `/opt/data`        | config, .env, sesi, profil Hermes |
| `docker-stack_mysql_data`       | `/var/lib/mysql`   | data MySQL              |
| `docker-stack_redis_data`       | `/data`            | data Redis (AOF)        |
| `docker-stack_mongo_data`       | `/data/db`         | data MongoDB            |

## Memindahkan data Hermes dari host lama

```bash
# di host lama
docker run --rm -v docker-stack_hermes_data:/data -v "$PWD":/backup \
  alpine tar czf /backup/hermes_data.tar.gz -C /data .

# di host baru (buat volume dulu)
docker volume create docker-stack_hermes_data
docker run --rm -v docker-stack_hermes_data:/data -v "$PWD":/backup \
  alpine tar xzf /backup/hermes_data.tar.gz -C /data
```

Sesuaikan nama volume dengan `docker volume ls` bila nama project berbeda.

## Menyesuaikan

- **Path super-app**: `export SUPER_APP_PATH=/path/repo` sebelum `install.sh`.
- **PHP ekstensi tambahan** untuk super-app: tambahkan ke `super-app/Dockerfile`,
  lalu `docker compose build super-app`.
- **Port Nginx**: ubah `"8081:80"` menjadi `"80:80"` bila port 80 bebas.
- **Redis/MySQL/Mongo ke internet**: jangan buka port database ke publik;
  gunakan VPN/SSH tunnel atau batasi `ports` ke `127.0.0.1`.
- **API server Hermes**: aktifkan `API_SERVER_ENABLED=true`,
  `API_SERVER_HOST=0.0.0.0`, `API_SERVER_KEY=<random>` di `.env` lalu
  `docker compose up -d`. Jangan buka ke internet tanpa HTTPS/auth.
- **Dashboard Hermes**: aktifkan `HERMES_DASHBOARD=1` + basic auth.

# Docker Stack: Nginx + PHP 8.2 + Node 26 + MySQL + Redis + MongoDB + Hermes

Paket portabel untuk menjalankan web server full-stack dan Hermes Agent di satu
host Ubuntu.

## Isi

- `docker-compose.yaml` — service: `nginx`, `php`, `node`, `mysql`, `redis`,
  `mongodb`, `hermes-agent`.
- `nginx/default.conf` — vhost Nginx (statis + PHP-FPM via service `php:9000`).
- `html/` — dokumen web yang dipakai Nginx dan PHP (`index.php`, `index.html`).
- `app/` — contoh app Node.js (`node:26-bookworm`) yang listen di port 3000.
- `install.sh` — cek prasyarat, membuat `.env` (password acak), `up -d`.
- `.env.example` — contoh variabel (opsional; `install.sh` membuat `.env`).

## Langkah install di komputer baru

```bash
# 1. Pasang Docker (sekali saja di host)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# logout, lalu login ulang

# 2. Salin folder ini ke komputer baru, lalu:
./install.sh
```

## Port

| Service   | Host port | Catatan                                   |
|-----------|-----------|-------------------------------------------|
| Nginx     | 8081      | ganti ke `80:80` bila port 80 bebas       |
| Node      | 3000      |                                            |
| MySQL     | 3306      | db `app`, user `app`                       |
| Redis     | 6380      | host 6379 biasanya dipakai Redis bawaan   |
| MongoDB   | 27017     | user `root`                                |
| Hermes    | 8642      | gateway API (API server default mati)      |

Kredensial database ada di `.env` (dibuat acak oleh `install.sh`).

## Setelah jalan

```bash
curl http://localhost:8081/           # Nginx/PHP
curl http://localhost:3000/           # Node
docker compose ps
docker compose logs -f

# Setup Hermes (provider/platform) — interaktif, sekali saja
docker exec -it hermes-agent hermes setup --portal
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

- **PHP ekstensi** (mis. `pdo_mysql`, `mysqli`): image `php:8.2-fpm` belum
  termasuk ekstensi DB. Tambahkan `php/Dockerfile` turunan dan ganti `image:`
  menjadi `build: ./php`.
- **Port Nginx**: ubah `"8081:80"` menjadi `"80:80"` bila port 80 bebas.
- **Redis/MySQL/Mongo ke internet**: jangan buka port database ke pubik;
  gunakan VPN/SSH tunnel atau batasi `ports` ke `127.0.0.1`.
- **API server Hermes**: aktifkan `API_SERVER_ENABLED=true`,
  `API_SERVER_HOST=0.0.0.0`, `API_SERVER_KEY=<random>` di `.env` lalu
  `docker compose up -d`. Jangan buka ke internet tanpa HTTPS/auth.
- **Dashboard Hermes**: aktifkan `HERMES_DASHBOARD=1` + basic auth.

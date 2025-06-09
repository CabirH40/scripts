#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Gerekli paketler (sistem güncellemesi olmadan)
apt install -yq ca-certificates curl gnupg lsb-release unzip docker.io docker-compose git

# Docker başlat
systemctl enable docker
systemctl start docker

# chromium dizini
mkdir -p /root/chromium
cd /root/chromium

# docker-compose.yaml
cat > docker-compose.yaml <<EOF
version: "3.3"
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=root
      - PASSWORD=yusur990
      - PUID=0
      - PGID=0
      - TZ=Europe/Istanbul
      - CHROME_CLI=https://discord.com/channels/819836895739248700/1380552086944747692
    volumes:
      - /root/chromium/config:/config
    ports:
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

# Eski config varsa sil
rm -rf /root/chromium/config

# Başlat
docker-compose down
docker-compose up -d

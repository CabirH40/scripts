#!/bin/bash

# 🚫 اجعل APT غير تفاعلي تماماً
export DEBIAN_FRONTEND=noninteractive

# 🚫 منع نافذة needrestart (Pending kernel upgrade أو إعادة تشغيل خدمات)
echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/99-auto.conf > /dev/null

# 📦 تثبيت جميع الحزم المطلوبة بصمت
echo "📦 Installing required packages..."
sudo apt-get install -y --no-install-recommends \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  htop ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev tmux \
  iptables curl nvme-cli git wget make jq libleveldb-dev build-essential \
  pkg-config ncdu tar clang bsdmainutils lsb-release libssl-dev \
  libreadline-dev libffi-dev gcc screen unzip lz4 gnupg

# 🐳 تثبيت Docker إذا لم يكن موجود
echo "🐳 Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y --no-install-recommends \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    docker-ce docker-ce-cli containerd.io

  echo "✅ Docker installed."
else
  echo "✅ Docker already installed."
fi

# 🔧 تثبيت Docker Compose إذا غير مثبت
echo "🔧 Checking Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
  echo "🔧 Installing Docker Compose..."
  VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  echo "✅ Docker Compose installed."
else
  echo "✅ Docker Compose already installed."
fi

# 👤 إضافة المستخدم إلى مجموعة Docker
echo "👤 Adding user to Docker group..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER

# 🕒 عرض المنطقة الزمنية
echo "🕒 Current timezone:"
realpath --relative-to /usr/share/zoneinfo /etc/localtime

# 🛑 إيقاف جميع الحاويات القديمة
echo "🛑 Stopping all running containers..."
docker ps -q | xargs -r docker stop

# 🧼 حذف مجلد config القديم إن وجد
rm -rf $HOME/chromium/config

# 📁 إنشاء مجلد chromium وملف docker-compose
echo "📁 Creating Chromium setup..."
mkdir -p $HOME/chromium && cd $HOME/chromium

cat <<EOF > docker-compose.yaml
version: "3.8"

services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=d
      - PASSWORD=d
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Istanbul
      - CHROME_CLI=--app=https://discord.com/login
    volumes:
      - ./config:/config
    ports:
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

# 🚀 تشغيل الحاوية مع دعم كلا النسختين
echo "🚀 Starting Chromium container..."
docker compose up -d || docker-compose up -d

# 📋 عرض الإصدارات والتأكيد
echo "📦 Docker version:"
docker version

echo "📦 Docker Compose version:"
docker-compose --version || docker compose version

echo "✅ All done!"
echo "🌐 Access Chromium via: http://your_server_ip:3010"
echo "🔐 Login: d / d"

#!/bin/bash

# 🧼 خنق أي تدخل تفاعلي
export DEBIAN_FRONTEND=noninteractive

echo "🔍 Checking if Docker is installed..."

# ✅ تثبيت Docker إذا ما كان موجود
if ! command -v docker &> /dev/null
then
    echo "🐳 Docker not found. Installing Docker..."

    sudo apt-get update -y
    sudo apt-get upgrade -y

    sudo apt-get install -y --no-install-recommends \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

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

# ✅ تثبيت Docker Compose إذا مو موجود
if ! command -v docker-compose &> /dev/null
then
    echo "🔧 Installing Docker Compose..."
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed."
else
    echo "✅ Docker Compose already installed."
fi

# 🛑 إيقاف جميع الحاويات الشغالة
echo "🛑 Stopping all running containers..."
docker ps -q | xargs -r docker stop

# 📁 إنشاء مجلد chromium وملف التكوين
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
      - CUSTOM_USER=furkan
      - PASSWORD=123456
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Istanbul
    volumes:
      - ./config:/config
    ports:
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

# 🚀 تشغيل الحاوية
echo "🚀 Starting Chromium container..."
docker-compose up -d

echo "✅ All done!"
echo "🌐 Access it via: http://your_server_ip:3010"
echo "🔐 Login: furkan / 123456"

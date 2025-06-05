#!/bin/bash

# 📂 إنشاء مجلد الشهادات
sudo mkdir -p /etc/caddy/certs

# 🌐 تحميل الشهادات من GitHub
curl -fsSL "https://raw.githubusercontent.com/CabirH40/scripts/main/certs/origin.crt" -o /etc/caddy/certs/origin.crt
curl -fsSL "https://raw.githubusercontent.com/CabirH40/scripts/main/certs/origin.key" -o /etc/caddy/certs/origin.key


# 🌍 جلب IP وتحويله لنطاق فرعي
IP=$(curl -s ifconfig.me)
OCTETS=$(echo $IP | cut -d '.' -f 3,4 | tr '.' '-')
DOMAIN="${OCTETS}.cabirh2000.uk"

# ⚙️ إعداد Caddyfile
CADDYFILE_PATH="/etc/caddy/Caddyfile"
sudo bash -c "echo '' > $CADDYFILE_PATH"

sudo bash -c "cat > $CADDYFILE_PATH" <<EOF
$DOMAIN:2053 {
  reverse_proxy localhost:9944
  tls /etc/caddy/certs/origin.crt /etc/caddy/certs/origin.key
}
EOF

# 🔓 فتح البورت
sudo ufw allow 2053/tcp
sudo chown -R caddy:caddy /etc/caddy/certs
sudo chmod 600 /etc/caddy/certs/*
# 🔁 إعادة تشغيل Caddy
sudo systemctl restart caddy

# ♻️ حذف أي متغير سابق وتعيين الجديد
sed -i '/cabir_auth_link/d' ~/.bashrc
FULL_DOMAIN="wss://${DOMAIN}:2053"
echo "export cabir_auth_link=${FULL_DOMAIN}" >> ~/.bashrc
export cabir_auth_link=$FULL_DOMAIN

# ✅ عرض النتيجة
echo ""
echo "🎯 WebSocket جاهز:"
echo "   $cabir_auth_link"

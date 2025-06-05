#!/bin/bash

# 🛡️ تأكد من وجود الأدوات
sudo apt update -y
sudo apt install -y curl ufw caddy

# 📂 إنشاء مجلد الشهادات
sudo mkdir -p /etc/caddy/certs

# 📥 تحميل الشهادات من GitHub
curl -fsSL "https://raw.githubusercontent.com/CabirH40/scripts/main/certs/origin.crt" -o /etc/caddy/certs/origin.crt
curl -fsSL "https://raw.githubusercontent.com/CabirH40/scripts/main/certs/origin.key" -o /etc/caddy/certs/origin.key

# 🌍 استخراج آخر رقمين من IP
IP=$(curl -s ifconfig.me)
OCTETS=$(echo $IP | cut -d '.' -f 3,4 | tr '.' '-')
DOMAIN="${OCTETS}.cabirh2000.uk"

# ⚙️ تعديل Caddyfile
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

# 🧠 تنظيف المتغيرات القديمة
sed -i '/cabir_auth_link/d' ~/.bashrc

# 💾 إنشاء متغير جديد
FULL_DOMAIN="wss://${DOMAIN}:2053"
echo "export cabir_auth_link=${FULL_DOMAIN}" >> ~/.bashrc
export cabir_auth_link=${FULL_DOMAIN}

# ✅ إظهار النتيجة
echo ""
echo "🎯 WebSocket رابطك الجاهز:"
echo "   $cabir_auth_link"
echo ""











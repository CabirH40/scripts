#!/bin/bash

# 🛡️ تأكد من وجود الأدوات (اختياري تقدر تفعلو)
# command -v curl >/dev/null || { echo "curl غير مثبت. الرجاء تثبيته أولاً."; exit 1; }

# 📂 إنشاء مجلد الشهادات إذا مش موجود
CERT_DIR="/etc/caddy/certs"
sudo mkdir -p "$CERT_DIR"

# 📥 تحميل الشهادات من GitHub
curl -fsSL "https://raw.githubusercontent.com/CabirH40/scripts/main/certs/origin.crt" -o "$CERT_DIR/origin.crt"
curl -fsSL "https://raw.githubusercontent.com/CabirH40/scripts/main/certs/origin.key" -o "$CERT_DIR/origin.key"

# 🌍 استخراج آخر رقمين من IP
IP=$(curl -4 -s https://api.ipify.org)
OCTETS=$(echo "$IP" | cut -d '.' -f 3,4 | tr '.' '-')
DOMAIN="${OCTETS}.cabirh2000.uk"

# ⚙️ تحديد مسار ملف Caddyfile
CADDYFILE_PATH="/etc/caddy/Caddyfile"

# 🧹 تنظيف Caddyfile إذا موجود، وإعادة كتابته
sudo bash -c "cat > $CADDYFILE_PATH" <<EOF
$DOMAIN:2053 {
  reverse_proxy localhost:9944
  tls /etc/caddy/certs/origin.crt /etc/caddy/certs/origin.key
}
EOF

# 🔓 فتح البورت
sudo ufw allow 2053/tcp

# 🔐 تصاريح الأمان
sudo chown -R caddy:caddy "$CERT_DIR"
sudo chmod 600 "$CERT_DIR"/*

# 🔁 إعادة تشغيل Caddy
sudo systemctl restart caddy

# 🧠 تنظيف القديم من bashrc
sed -i '/cabir_auth_link/d' ~/.bashrc

# 💾 إنشاء متغير جديد
FULL_DOMAIN="wss://${DOMAIN}:2053"
echo "export cabir_auth_link=${FULL_DOMAIN}" >> ~/.bashrc
export cabir_auth_link=${FULL_DOMAIN}

# ✅ عرض النتيجة
echo ""
echo "🎯 WebSocket رابطك الجاهز:"
echo "   $cabir_auth_link"
echo ""

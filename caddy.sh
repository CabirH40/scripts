#!/bin/bash

set -e

# 🧠 معلومات السيرفر الأساسي
MAIN_SERVER_IP="91.151.93.184"   # ← عدّل هذا
MAIN_SERVER_USER="root"
MAIN_SERVER_PASS="Meymatibasimiz47."

# 🧩 تثبيت sshpass لو مش موجود
if ! command -v sshpass &>/dev/null; then
  sudo apt update
  sudo apt install -y sshpass
fi

# 🌍 استخراج آخر رقمين من IP العام
IP=$(curl -s ifconfig.me)
OCTETS=$(echo "$IP" | cut -d '.' -f 3,4 | tr '.' '-')
DOMAIN="${OCTETS}.cabirh2000.uk"
FULL_DOMAIN="wss://${DOMAIN}:2053"

# 📁 إنشاء مجلد الشهادات
CERT_DIR="/etc/caddy/certs"
sudo mkdir -p "$CERT_DIR"

# 📥 سحب ملفات الشهادة من السيرفر الأساسي
sshpass -p "$MAIN_SERVER_PASS" scp "$MAIN_SERVER_USER@$MAIN_SERVER_IP:/etc/caddy/certs/origin.crt" "$CERT_DIR/"
sshpass -p "$MAIN_SERVER_PASS" scp "$MAIN_SERVER_USER@$MAIN_SERVER_IP:/etc/caddy/certs/origin.key" "$CERT_DIR/"

# 🛠️ كتابة ملف Caddyfile من جديد
CADDYFILE_PATH="/etc/caddy/Caddyfile"
sudo bash -c "cat > $CADDYFILE_PATH" <<EOF
$DOMAIN:2053 {
  reverse_proxy localhost:9944
  tls $CERT_DIR/origin.crt $CERT_DIR/origin.key
}
EOF

# 🔓 فتح البورت
sudo ufw allow 2053/tcp

# 🔁 إعادة تشغيل Caddy
sudo systemctl restart caddy

# 🧼 حذف المتغير القديم
PROFILE_FILE="$HOME/.bashrc"
sed -i '/cabir_auth_link=/d' "$PROFILE_FILE"

# 🧠 حفظ متغير جديد
EXPORT_LINE="export cabir_auth_link_2053=${FULL_DOMAIN}"
echo "$EXPORT_LINE" >> "$PROFILE_FILE"
export cabir_auth_link_2053="$FULL_DOMAIN"

# ✅ عرض النتيجة
echo ""
echo "🎯 رابط WebSocket الجديد:"
echo "   $cabir_auth_link_2053"
echo ""
echo "💾 تم حفظ الرابط باسم: cabir_auth_link_2053"

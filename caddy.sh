#!/bin/bash

set -e

# 🌍 1. استخراج آخر رقمين من IP العام
IP=$(curl -s ifconfig.me)
OCTETS=$(echo "$IP" | cut -d '.' -f 3,4 | tr '.' '-')
DOMAIN="${OCTETS}.cabirh2000.uk"
FULL_DOMAIN="wss://${DOMAIN}:2053"

# 📁 2. إنشاء مجلد الشهادات إن لم يكن موجودًا
CERT_DIR="/etc/caddy/certs"
sudo mkdir -p "$CERT_DIR"

# 📤 3. سحب ملفات التشفير من السيرفر الأساسي (عدّل IP حسب السيرفر الأساسي)
SOURCE_SERVER="root@YOUR_MAIN_SERVER_IP"
REMOTE_CERT_PATH="/etc/caddy/certs"

scp "$SOURCE_SERVER:$REMOTE_CERT_PATH/origin.crt" "$CERT_DIR/"
scp "$SOURCE_SERVER:$REMOTE_CERT_PATH/origin.key" "$CERT_DIR/"

# 🛠️ 4. إعادة كتابة ملف Caddyfile بالكامل
CADDYFILE_PATH="/etc/caddy/Caddyfile"

sudo bash -c "cat > $CADDYFILE_PATH" <<EOF
$DOMAIN:2053 {
  reverse_proxy localhost:9944
  tls $CERT_DIR/origin.crt $CERT_DIR/origin.key
}
EOF

# 🔓 5. فتح البورت 2053 في الجدار الناري
sudo ufw allow 2053/tcp

# 🔁 6. إعادة تشغيل Caddy
sudo systemctl restart caddy

# 🧼 7. حذف المتغير القديم إن وُجد
PROFILE_FILE="$HOME/.bashrc"
sed -i '/cabir_auth_link=/d' "$PROFILE_FILE"

# 🧠 8. تعيين متغير جديد باسم مختلف
EXPORT_LINE="export cabir_auth_link_2053=${FULL_DOMAIN}"
echo "$EXPORT_LINE" >> "$PROFILE_FILE"
export cabir_auth_link_2053="$FULL_DOMAIN"

# ✅ 9. عرض النتيجة
echo ""
echo "🎯 رابط WebSocket الجديد:"
echo "   $cabir_auth_link_2053"
echo ""
echo "💾 تم حفظ الرابط كمتغير دائم باسم: cabir_auth_link_2053"

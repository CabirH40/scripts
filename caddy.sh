#!/bin/bash

set -e

# إعدادات الاتصال بالسيرفر المركزي
CENTRAL_IP="91.151.93.184"
CENTRAL_USER="root"
CENTRAL_PASS="Meymatibasimiz47"
REMOTE_CERT_DIR="/etc/caddy/certs"

# مسار الملفات المحلي
LOCAL_CERT_DIR="/etc/caddy/certs"
CADDYFILE_PATH="/etc/caddy/Caddyfile"

# 🧠 استخراج آخر رقمين من الـ IP
IP=$(curl -s ifconfig.me)
OCTETS=$(echo "$IP" | cut -d '.' -f 3,4 | tr '.' '-')
DOMAIN="${OCTETS}.cabirh2000.uk"
FULL_DOMAIN="wss://${DOMAIN}:2053"

# 📁 إنشاء مجلد الشهادات إن لم يكن موجود
mkdir -p "$LOCAL_CERT_DIR"

# ⬇️ تحميل ملفات الشهادة
sshpass -p "$CENTRAL_PASS" scp -o StrictHostKeyChecking=no "$CENTRAL_USER@$CENTRAL_IP:$REMOTE_CERT_DIR/origin.crt" "$LOCAL_CERT_DIR/origin.crt"
sshpass -p "$CENTRAL_PASS" scp -o StrictHostKeyChecking=no "$CENTRAL_USER@$CENTRAL_IP:$REMOTE_CERT_DIR/origin.key" "$LOCAL_CERT_DIR/origin.key"

# 📝 تحديث Caddyfile
cat > "$CADDYFILE_PATH" <<EOF
$DOMAIN:2053 {
  reverse_proxy localhost:9944
  tls $LOCAL_CERT_DIR/origin.crt $LOCAL_CERT_DIR/origin.key
}
EOF

# 🔁 إعادة تشغيل Caddy
systemctl restart caddy

# 🧼 حذف المتغير القديم من .bashrc
sed -i '/cabir_auth_link/d' ~/.bashrc

# 💾 إضافة المتغير الجديد
echo "export cabir_auth_link=$FULL_DOMAIN" >> ~/.bashrc
export cabir_auth_link=$FULL_DOMAIN

# ✅ طباعة النتيجة
echo ""
echo "🔐 الشهادة تم سحبها بنجاح من $CENTRAL_IP"
echo "🛠️ تم إعداد Caddy على البورت 2053 للدومين: $DOMAIN"
echo "🌐 رابط الاتصال WebSocket:"
echo "   $cabir_auth_link"

#!/bin/bash

# 📁 مكان تركيب الشهادات على السيرفر
REMOTE_CERT_DIR="/etc/caddy/certs"

# 🔗 روابط مباشرة من GitHub للملفين
CRT_URL="https://raw.githubusercontent.com/CabirH40/scripts/main/New%20folder/certs/origin.crt"
KEY_URL="https://raw.githubusercontent.com/CabirH40/scripts/main/New%20folder/certs/origin.key"

# 📂 تأكد من وجود المسار
mkdir -p "$REMOTE_CERT_DIR"

# ⬇️ تحميل الشهادة والمفتاح
curl -fsSL "$CRT_URL" -o "$REMOTE_CERT_DIR/origin.crt" && echo "✅ تم تحميل origin.crt"
curl -fsSL "$KEY_URL" -o "$REMOTE_CERT_DIR/origin.key" && echo "✅ تم تحميل origin.key"

# 🛡️ صلاحيات
chmod 600 "$REMOTE_CERT_DIR"/origin.*
chown root:root "$REMOTE_CERT_DIR"/origin.*

# 🔁 إعادة تشغيل Caddy إن وجد
if systemctl list-units --type=service | grep -q caddy; then
  systemctl restart caddy && echo "🔁 تم إعادة تشغيل Caddy"
else
  echo "ℹ️ Caddy غير موجود أو غير شغال حالياً"
fi

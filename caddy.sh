#!/bin/bash

set -e

# 🚀 1. تثبيت Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https

curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/caddy-stable-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list

sudo apt update -y
sudo apt install -y caddy

# 🌍 2. استخراج آخر رقمين من IP العام
IP=$(curl -s ifconfig.me)
OCTETS=$(echo $IP | cut -d '.' -f 3,4 | tr '.' '-')
DOMAIN="${OCTETS}.cabirh2000.uk"
FULL_DOMAIN="wss://${DOMAIN}:1400"

# ⚙️ 3. إعداد Caddyfile
CADDYFILE_PATH="/etc/caddy/Caddyfile"

sudo bash -c "cat > $CADDYFILE_PATH" <<EOF
$DOMAIN:1400 {
  reverse_proxy localhost:9944

  encode gzip

  tls {
    protocols tls1.2 tls1.3
  }
}
EOF

# 🔓 4. فتح البورت
sudo ufw allow 1400/tcp

# 🔁 5. إعادة تشغيل Caddy
sudo systemctl restart caddy

# 🧠 6. حفظ الرابط كمتغير دائم باسم cabir_auth_link
EXPORT_LINE="export cabir_auth_link=${FULL_DOMAIN}"
PROFILE_FILE="$HOME/.bashrc"

if ! grep -q "cabir_auth_link" "$PROFILE_FILE"; then
  echo "$EXPORT_LINE" >> "$PROFILE_FILE"
  echo "✅ تم حفظ الرابط كمتغير دائم: cabir_auth_link"
else
  sed -i "s|^export cabir_auth_link=.*|$EXPORT_LINE|" "$PROFILE_FILE"
  echo "🔄 تم تحديث المتغير الدائم: cabir_auth_link"
fi

# ⏩ تحميل المتغير فورًا في الجلسة الحالية
export cabir_auth_link=$FULL_DOMAIN

# ✅ 7. عرض النتيجة
echo ""
echo "🎯 رابط WebSocket الخاص بك:"
echo "   $cabir_auth_link"
echo ""
echo "💡 يمكنك استخدامه دائماً عبر:"
echo "   \$cabir_auth_link"

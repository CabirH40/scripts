#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

# 🛡️ تأكد من وجود الأدوات (اختياري تقدر تفعلو)
# command -v curl >/dev/null || { echo "curl غير مثبت. الرجاء تثبيته أولاً."; exit 1; }

# 📂 إنشاء مجلد الشهادات إذا مش موجود
CERT_DIR="/etc/caddy/certs"
mkdir -p "$CERT_DIR"

# 📥 تحميل الشهادات من GitHub
curl -fsSL "https://raw.githubusercontent.com/CabirH40/scripts/main/certs/origin.crt" -o "$CERT_DIR/origin.crt"
curl -fsSL "https://raw.githubusercontent.com/CabirH40/scripts/main/certs/origin.key" -o "$CERT_DIR/origin.key"

# 🌍 استخراج آخر رقمين من IP
IP=$(curl -4 -s --max-time 8 https://api.ipify.org || true)
if [[ -z "$IP" ]]; then
  echo "❌ Unable to detect public IPv4."
  exit 1
fi
OCTETS=$(echo "$IP" | cut -d '.' -f 3,4 | tr '.' '-')
DOMAIN="${OCTETS}.gorahal.com"

# ⚙️ تحديد مسار ملف Caddyfile
CADDYFILE_PATH="/etc/caddy/Caddyfile"

# 🧹 تنظيف Caddyfile إذا موجود، وإعادة كتابته
cat > "$CADDYFILE_PATH" <<EOF
$DOMAIN:2053 {
  reverse_proxy localhost:9944
  tls /etc/caddy/certs/origin.crt /etc/caddy/certs/origin.key
}
EOF

# 🔓 فتح البورت
ufw allow 2053/tcp || true

# 🔐 تصاريح الأمان
chown -R caddy:caddy "$CERT_DIR"
chmod 600 "$CERT_DIR"/*

# 🔁 إعادة تشغيل Caddy
systemctl restart caddy

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

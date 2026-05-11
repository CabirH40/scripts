#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

# 🛡️ تأكد من وجود curl
command -v curl >/dev/null || { echo "❌ curl غير مثبت. الرجاء تثبيته أولاً."; exit 1; }

# 📝 مسار Caddyfile
CADDYFILE_PATH="/etc/caddy/Caddyfile"

# ⚙️ تأكد من وجود الملف
mkdir -p /etc/caddy
touch "$CADDYFILE_PATH"

# 🧹 تفريغ ملف Caddyfile
: > "$CADDYFILE_PATH"

# 🌍 الحصول على IP واستخراج Octets
IP=$(curl -4 -s --max-time 8 https://api.ipify.org || true)
if [[ -z "$IP" ]]; then
  echo "❌ Unable to detect public IPv4."
  exit 1
fi
OCTET_3=$(echo "$IP" | cut -d '.' -f 3)
OCTET_4=$(echo "$IP" | cut -d '.' -f 4)
BASE_DOMAIN="${OCTET_3}-${OCTET_4}"

# 📝 إعداد الدومين الرئيسي
MAIN_DOMAIN="${BASE_DOMAIN}.gorahal.com"
cat >> "$CADDYFILE_PATH" <<EOF
$MAIN_DOMAIN {
    reverse_proxy 127.0.0.1:9944
}
EOF

# 💾 حفظ رابط النود الرئيسي
mkdir -p /root/link
echo "https://webapp.mainnet.stages.humanode.io/humanode/wss%3A%2F%2F$MAIN_DOMAIN" > /root/link/link.txt

# 🔁 إنشاء روابط node1 إلى node11
for i in {1..11}; do
  DOMAIN="${BASE_DOMAIN}${i}.gorahal.com"
  RPC_PORT=$((9944 + i))

  # ✏️ كتابة في Caddyfile
  cat >> "$CADDYFILE_PATH" <<EOF
$DOMAIN {
    reverse_proxy 127.0.0.1:$RPC_PORT
}
EOF

  # 📁 إنشاء مجلد الرابط
  NODE_LINK_DIR="/root/script/node${i}/link"
  mkdir -p "$NODE_LINK_DIR"

  # 💾 حفظ الرابط
  LINK="https://webapp.mainnet.stages.humanode.io/humanode/wss%3A%2F%2F${DOMAIN}"
  echo "$LINK" > "$NODE_LINK_DIR/link.txt"
done

# 🔄 إعادة تشغيل Caddy
systemctl restart caddy && echo "✅ تم إعادة تشغيل Caddy." || echo "❌ فشل في إعادة تشغيل Caddy."

# 📄 عرض كل الروابط
echo -e "\n📄 روابط النودات:"
echo "Root: $(cat /root/link/link.txt)"
for i in {1..11}; do
  echo "Node$i: $(cat /root/script/node${i}/link/link.txt)"
done

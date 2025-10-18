#!/bin/bash

# 🛡️ تأكد من وجود curl
command -v curl >/dev/null || { echo "❌ curl غير مثبت. الرجاء تثبيته أولاً."; exit 1; }

# 📝 مسار Caddyfile
CADDYFILE_PATH="/etc/caddy/Caddyfile"

# ⚙️ تأكد من وجود الملف
sudo mkdir -p /etc/caddy
sudo touch $CADDYFILE_PATH

# 🧹 تفريغ ملف Caddyfile
sudo bash -c "echo '' > $CADDYFILE_PATH"

# 🌍 الحصول على IP واستخراج Octets
IP=$(curl -4 -s https://api.ipify.org)
OCTET_3=$(echo "$IP" | cut -d '.' -f 3)
OCTET_4=$(echo "$IP" | cut -d '.' -f 4)
BASE_DOMAIN="${OCTET_3}-${OCTET_4}"

# 📝 إعداد الدومين الرئيسي
MAIN_DOMAIN="${BASE_DOMAIN}.cabirh2000.uk"
sudo bash -c "cat >> $CADDYFILE_PATH" <<EOF
$MAIN_DOMAIN {
    reverse_proxy 127.0.0.1:9944
}
EOF

# 💾 حفظ رابط النود الرئيسي
mkdir -p /root/link
echo "https://webapp.mainnet.stages.humanode.io/humanode/wss%3A%2F%2F$MAIN_DOMAIN" > /root/link/link.txt

# 🔁 إنشاء روابط node1 إلى node9
for i in {1..11}; do
  DOMAIN="${BASE_DOMAIN}${i}.cabirh2000.uk"
  RPC_PORT=$((9944 + i))

  # ✏️ كتابة في Caddyfile
  sudo bash -c "cat >> $CADDYFILE_PATH" <<EOF
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
sudo systemctl restart caddy && echo "✅ تم إعادة تشغيل Caddy." || echo "❌ فشل في إعادة تشغيل Caddy."

# 📄 عرض كل الروابط
echo -e "\n📄 روابط النودات:"
echo "Root: $(cat /root/link/link.txt)"
for i in {1..11}; do
  echo "Node$i: $(cat /root/script/node${i}/link/link.txt)"
done

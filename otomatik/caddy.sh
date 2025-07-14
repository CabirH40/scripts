#!/bin/bash

# 🛡️ تأكد من وجود الأدوات
command -v curl >/dev/null || { echo "curl غير مثبت. الرجاء تثبيته أولاً."; exit 1; }

# 📝 مسار Caddyfile
CADDYFILE_PATH="/etc/caddy/Caddyfile"

# 🧹 تفريغ ملف Caddyfile
sudo bash -c "echo '' > $CADDYFILE_PATH"

# 🌍 استخراج آخر رقمين من الـ IP (Octet 3 و 4)
IP=$(curl -4 -s https://api.ipify.org)
OCTETS=$(echo "$IP" | cut -d '.' -f 3,4 | tr '.' '-')

# 📄 إنشاء reverse_proxy للـ Root أولاً
sudo bash -c "echo \"${OCTETS}.cabirh2000.uk {
    reverse_proxy 127.0.0.1:9944
}\" >> $CADDYFILE_PATH"

# 💾 إنشاء رابط للـ Root
mkdir -p /root/link
echo "https://webapp.mainnet.stages.humanode.io/humanode/wss%3A%2F%2F${OCTETS}.cabirh2000.uk" > /root/link/link.txt

# 🔁 إنشاء لـ Node1 - Node9
for i in {1..9}; do
  # زيادة على آخر خانة للـ IP
  LAST_OCTET=$(echo "$IP" | cut -d '.' -f 4)
  NEW_LAST_OCTET=$(( LAST_OCTET + $i ))
  DOMAIN="36-${NEW_LAST_OCTET}.cabirh2000.uk"
  RPC_PORT=$((9944 + $i))
  
  # ✏️ كتابة في Caddyfile
  sudo bash -c "echo \"${DOMAIN} {
    reverse_proxy 127.0.0.1:${RPC_PORT}
}\" >> $CADDYFILE_PATH"
  
  # 💾 حفظ رابط الـ WebApp للنود
  mkdir -p /root/script/node${i}/link
  echo "https://webapp.mainnet.stages.humanode.io/humanode/wss%3A%2F%2F${DOMAIN}" > /root/script/node${i}/link/link.txt
done

# 🔄 إعادة تشغيل Caddy
sudo systemctl restart caddy

echo "✅ تم إنشاء Caddyfile وتوليد الروابط لكل النودات."

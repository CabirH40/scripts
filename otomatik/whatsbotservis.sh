#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

# 🔧 1) إنشاء whatsbot.service لـ root
WORKDIR="/root/script/whatsapp-bot"

cat <<EOF > /etc/systemd/system/whatsbot.service
[Unit]
Description=WhatsBot Monitor Root
After=network.target

[Service]
ExecStart=/usr/bin/python3 $WORKDIR/whatsbot.py
Restart=always
RestartSec=5
User=root
WorkingDirectory=$WORKDIR

[Install]
WantedBy=multi-user.target
EOF

echo "✅ تم إنشاء whatsbot.service (لـ root)"

# 🔁 2) إنشاء خدمات node1 إلى node11
for i in {1..11}; do
  WORKDIR="/root/script/node$i/whatsapp-bot"

  cat <<EOF > /etc/systemd/system/whatsbot$i.service
[Unit]
Description=WhatsBot Monitor $i
After=network.target

[Service]
ExecStart=/usr/bin/python3 $WORKDIR/whatsbot.py
Restart=always
RestartSec=5
User=root
WorkingDirectory=$WORKDIR

[Install]
WantedBy=multi-user.target
EOF

  echo "✅ تم إنشاء whatsbot$i.service"
done

# 🔄 3) إعادة تحميل systemd وتشغيل الخدمات
echo "♻️ عمل إعادة تحميل لـ systemd..."
systemctl daemon-reload

# 🚀 4) تفعيل وتشغيل جميع الخدمات
echo "🚀 تفعيل وتشغيل whatsbot.service"
systemctl enable --now whatsbot.service

for i in {1..11}; do
  echo "🚀 تفعيل وتشغيل whatsbot$i.service"
  systemctl enable --now whatsbot$i.service
done

echo "🎉 كل خدمات WhatsBot اشتغلت وتفعلت ✔️"

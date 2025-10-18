#!/bin/bash

# 🔧 1) إنشاء whatsbot.service (لـ root/node1)
WORKDIR="/root/script/node1/whatsapp-bot"

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

# 🔁 2) إنشاء whatsbot1.service إلى whatsbot9.service
for i in {10..11}; do
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

for i in {10..11}; do
  echo "🚀 تفعيل وتشغيل whatsbot$i.service"
  systemctl enable --now whatsbot$i.service
done

echo "🎉 كل خدمات WhatsBot اشتغلت وتفعلت ✔️"

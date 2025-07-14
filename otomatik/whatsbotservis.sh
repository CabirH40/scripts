#!/bin/bash

for i in {1..10}
do
  if [ $i -eq 1 ]; then
    WORKDIR="/root/script/node1/whatsapp-bot"
  else
    NODE_NUM=$((i - 1))
    WORKDIR="/node$NODE_NUM/script/whatsapp-bot"
  fi

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

done

echo "✅ تمت إنشاء ملفات خدمات WhatsBot 1 إلى 10."
echo "♻️ عمل إعادة تحميل لـ systemd..."
systemctl daemon-reload

for i in {1..10}
do
  echo "🚀 تفعيل وتشغيل whatsbot$i.service"
  systemctl enable --now whatsbot$i.service
done

echo "🎉 كل خدمات WhatsBot اشتغلت وتفعلت ✔️"

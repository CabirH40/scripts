#!/bin/bash

for i in {1..10}
do
  if [ $i -eq 1 ]; then
    SCRIPT_PATH="/root/script/check_process-humanode.py"
  else
    NODE_NUM=$((i - 1))
    SCRIPT_PATH="/node$NODE_NUM/script/check_process-humanode.py"
  fi

  cat <<EOF > /etc/systemd/system/humanode-checker$i.service
[Unit]
Description=Humanode Process Checker $i
After=network.target

[Service]
ExecStart=/usr/bin/python3 $SCRIPT_PATH
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

done

echo "✅ تم إنشاء خدمات Humanode Process Checker 1 إلى 10."
echo "♻️ عمل إعادة تحميل لـ systemd..."
systemctl daemon-reload

for i in {1..10}
do
  echo "🚀 تفعيل وتشغيل humanode-checker$i.service"
  systemctl enable --now humanode-checker$i.service
done

echo "🎯 كل الـ Humanode Checkers شغالة ومفعّلة ✔️"

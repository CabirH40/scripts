#!/bin/bash

for i in {1..10}
do
  if [ $i -eq 1 ]; then
    WORKDIR="/root/.humanode/workspaces/default"
  else
    NODE_NUM=$((i - 1))
    WORKDIR="/home/node$NODE_NUM/.humanode/workspaces/default"
  fi

  cat <<EOF > /etc/systemd/system/humanode$i.service
[Unit]
Description=Humanode Root Node $i
After=network.target

[Service]
User=root
WorkingDirectory=$WORKDIR
ExecStart=$WORKDIR/run-node.sh

MemoryMax=1536M
CPUQuota=80%
LimitNOFILE=1048576

Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

done

echo "✅ تمت إنشاء ملفات الخدمات لـ Humanode Node 1 إلى 10."
echo "♻️ عمل إعادة تحميل لـ systemd..."
systemctl daemon-reload

for i in {1..10}
do
  echo "🚀 تفعيل وتشغيل humanode$i.service"
  systemctl enable --now humanode$i.service
done

echo "🎉 كل النودات اشتغلت وتفعلت ✔️"

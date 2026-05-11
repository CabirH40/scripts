#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

# 🔧 1) إنشاء humanode.service لـ root
WORKDIR="/root/.humanode/workspaces/default"

cat <<EOF > /etc/systemd/system/humanode.service
[Unit]
Description=Humanode Root Node
After=network.target

[Service]
User=root
WorkingDirectory=$WORKDIR
ExecStart=$WORKDIR/run-node.sh

MemoryMax=1024M
CPUQuota=75%
LimitNOFILE=1048576

Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

echo "✅ تم إنشاء humanode.service (لـ root)"

# 🔁 2) إنشاء humanode1.service إلى humanode9.service
for i in {1..11}; do
  USERNAME="node$i"
  WORKDIR="/home/$USERNAME/.humanode/workspaces/default"

  cat <<EOF > /etc/systemd/system/humanode$i.service
[Unit]
Description=Humanode Node $i
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$WORKDIR
ExecStart=$WORKDIR/run-node.sh

MemoryMax=1024M
CPUQuota=75%
LimitNOFILE=1048576

Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

  echo "✅ تم إنشاء humanode$i.service"
done

# 🔄 3) إعادة تحميل systemd وتشغيل الخدمات
echo "♻️ عمل إعادة تحميل لـ systemd..."
systemctl daemon-reload

# 🚀 4) تفعيل وتشغيل جميع الخدمات
echo "🚀 تفعيل وتشغيل humanode.service"
systemctl enable --now humanode.service

for i in {1..11}; do
  echo "🚀 تفعيل وتشغيل humanode$i.service"
  systemctl enable --now humanode$i.service
done

echo "🎉 كل الخدمات اشتغلت وتفعلت ✔️"

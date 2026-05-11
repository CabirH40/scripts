#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

# ✅ 1) إنشاء humanode-checker.service لـ root
SCRIPT_PATH="/root/script/check_process-humanode.py"

cat <<EOF > /etc/systemd/system/humanode-checker.service
[Unit]
Description=Humanode Process Checker Root
After=network.target

[Service]
ExecStart=/usr/bin/python3 $SCRIPT_PATH
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "✅ تم إنشاء humanode-checker.service (لـ root)"

# 🔁 2) إنشاء خدمات node1 إلى node11
for i in {1..11}; do
  SCRIPT_PATH="/home/node$i/script/check_process-humanode.py"

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

  echo "✅ تم إنشاء humanode-checker$i.service"
done

# 🔄 3) إعادة تحميل systemd وتشغيل الخدمات
echo "♻️ عمل إعادة تحميل لـ systemd..."
systemctl daemon-reload

# 🚀 4) تفعيل وتشغيل الخدمات
echo "🚀 تفعيل وتشغيل humanode-checker.service"
systemctl enable --now humanode-checker.service

for i in {1..11}; do
  echo "🚀 تفعيل وتشغيل humanode-checker$i.service"
  systemctl enable --now humanode-checker$i.service
done

echo "🎯 كل الـ Humanode Checkers شغالة ومفعّلة ✔️"

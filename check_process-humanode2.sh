#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must run as root." >&2
    exit 1
fi

SERVICE_NAME="check_process-humanode.service"
SCRIPT_PATH="/root/script/check_process-humanode.py"

# ✅ التحقق مما إذا كانت الخدمة مفعّلة والسكريبت موجود
if systemctl is-enabled --quiet "$SERVICE_NAME" && [ -f "$SCRIPT_PATH" ]; then
    echo "✅ الخدمة $SERVICE_NAME موجودة وفعالة، والسكريبت موجود. يتم التخطي."
    exit 0
fi

echo "📦 جاري تثبيت خدمة فحص humanode..."

# ✅ تحميل سكربت Python
echo "⬇️ تحميل check_process-humanode.py..."
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/check_process-humanode.py -O "$SCRIPT_PATH" && chmod +x "$SCRIPT_PATH"

# ✅ إنشاء ملف خدمة systemd
echo "⚙️ إنشاء خدمة systemd..."
cat <<EOF > "/etc/systemd/system/$SERVICE_NAME"
[Unit]
Description=Humanode Process Checker
After=network.target

[Service]
ExecStart=/usr/bin/python3 $SCRIPT_PATH
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

# ✅ تفعيل وتشغيل الخدمة
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

echo "✅ تم تفعيل الخدمة $SERVICE_NAME بنجاح."
exit

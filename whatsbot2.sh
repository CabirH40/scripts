#!/bin/bash

SERVICE_NAME="whatsbot.service"
SCRIPT_PATH="/root/whatsapp-bot/whatsbot.py"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

# ✅ إذا الخدمة مثبتة والسكريبت موجود، لا تعمل شيء
if systemctl is-enabled --quiet "$SERVICE_NAME" && [ -f "$SCRIPT_PATH" ]; then
  echo "✅ الخدمة $SERVICE_NAME و $SCRIPT_PATH موجودة. لا حاجة للتثبيت، يتم التخطي."
  exit 0
fi

echo "🧪 الخدمة غير موجودة أو السكربت ناقص. جاري التثبيت..."

# 1. إنشاء مجلد البوت
mkdir -p /root/whatsapp-bot

# 2. تحميل السكربت
wget -q -O "$SCRIPT_PATH" https://raw.githubusercontent.com/CabirH40/script.sh/main/whatsbot.py
chmod +x "$SCRIPT_PATH"

# 3. إنشاء ملف الخدمة
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=WhatsBot Monitor
After=network.target

[Service]
ExecStart=/usr/bin/python3 $SCRIPT_PATH
Restart=always
RestartSec=5
User=root
WorkingDirectory=/root/whatsapp-bot

[Install]
WantedBy=multi-user.target
EOF

# 4. تفعيل وتشغيل الخدمة
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo "✅ تم التثبيت وتشغيل الخدمة: $SERVICE_NAME"

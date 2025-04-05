#!/bin/bash

# 1. إنشاء المجلد
mkdir -p /root/whatsapp-bot

# 2. تحميل السكربت
wget -O /root/whatsapp-bot/whatsbot.py https://raw.githubusercontent.com/CabirH40/script.sh/main/whatsbot.py

# 3. إنشاء خدمة systemd
cat <<EOF > /etc/systemd/system/whatsbot.service
[Unit]
Description=WhatsBot Monitor
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/whatsapp-bot/whatsbot.py
Restart=always
User=root
WorkingDirectory=/root/whatsapp-bot

[Install]
WantedBy=multi-user.target
EOF

# 4. إعادة تحميل النظام وتشغيل الخدمة
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable whatsbot.service
systemctl start whatsbot.service

# 5. عرض حالة الخدمة
systemctl status whatsbot.service

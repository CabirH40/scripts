#!/bin/bash

# 🧠 أولاً: رفع limit لعدد الملفات المفتوحة (بدون reboot)
echo "🔧 ضبط LimitNOFILE إلى 65535..."

# إعداد دائم لـ systemd بدون ريستارت
mkdir -p /etc/systemd/system.conf.d
cat <<EOF > /etc/systemd/system.conf.d/nofile.conf
[Manager]
DefaultLimitNOFILE=65535
EOF

# تفعيل ulimit للجلسة الحالية (مؤقت)
ulimit -n 65535

# إعادة تحميل systemd
systemctl daemon-reexec
systemctl daemon-reload

# 📥 تحميل السكربتات من GitHub
echo "⬇️ تحميل سكربتات Ocean..."
curl -o /root/restart_ineligible.py https://raw.githubusercontent.com/CabirH40/script.sh/main/ocean/restart_ineligible.py
curl -o /root/restart_missing.py https://raw.githubusercontent.com/CabirH40/script.sh/main/ocean/restart_missing.py


# 🛡️ إعطاء صلاحيات تنفيذ
chmod +x /root/restart_ineligible.py
chmod +x /root/restart_missing.py

# 🛠️ إنشاء restart-ineligible.service
cat <<EOF > /etc/systemd/system/restart-ineligible.service
[Unit]
Description=Restart Ineligible Ocean Nodes

[Service]
Type=simple
ExecStart=/usr/bin/python3 /root/restart_ineligible.py
TimeoutStartSec=10220

[Install]
WantedBy=multi-user.target
EOF

# ⏰ restart-ineligible.timer (00,06,12,18)
cat <<EOF > /etc/systemd/system/restart-ineligible.timer
[Unit]
Description=Run restart_ineligible.py every 6 hours (00:00, 06:00, 12:00, 18:00)

[Timer]
OnCalendar=0/6:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 🛠️ إنشاء restart-missing.service
cat <<EOF > /etc/systemd/system/restart-missing.service
[Unit]
Description=Restart Missing Ocean Nodes

[Service]
Type=simple
ExecStart=/usr/bin/python3 /root/restart_missing.py
TimeoutStartSec=10220

[Install]
WantedBy=multi-user.target
EOF

# ⏰ restart-missing.timer (03,09,15,21)
cat <<EOF > /etc/systemd/system/restart-missing.timer
[Unit]
Description=Run restart_missing.py every 6 hours (03:00, 09:00, 15:00, 21:00)

[Timer]
OnCalendar=3/6:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 🚀 تفعيل وتشغيل التايمرات
systemctl enable --now restart-ineligible.timer
systemctl enable --now restart-missing.timer

echo "✅ تم رفع limit وتفعيل التايمرات بنجاح بدون ريستارت!"

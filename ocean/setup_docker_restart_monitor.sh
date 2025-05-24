#!/bin/bash

# تحميل السكربتات من GitHub
curl -o /root/restart_ineligible.py https://raw.githubusercontent.com/CabirH40/script/main/ocean/restart_ineligible.py
curl -o /root/restart_missing.py https://raw.githubusercontent.com/CabirH40/script/main/ocean/restart_missing.py

# إعطاء صلاحيات التنفيذ (احتياطاً)
chmod +x /root/restart_ineligible.py
chmod +x /root/restart_missing.py

# إنشاء restart-ineligible.service
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

# إنشاء restart-ineligible.timer (كل 6 ساعات بدءاً من منتصف الليل)
cat <<EOF > /etc/systemd/system/restart-ineligible.timer
[Unit]
Description=Run restart_ineligible.py every 6 hours (00:00, 06:00, 12:00, 18:00)

[Timer]
OnCalendar=0/6:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# إنشاء restart-missing.service
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

# إنشاء restart-missing.timer (كل 6 ساعات بدءاً من الساعة 03:00)
cat <<EOF > /etc/systemd/system/restart-missing.timer
[Unit]
Description=Run restart_missing.py every 6 hours (03:00, 09:00, 15:00, 21:00)

[Timer]
OnCalendar=3/6:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# إعادة تحميل النظام وتفعيل التايمرات
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now restart-ineligible.timer
systemctl enable --now restart-missing.timer

echo "✅ تم تحميل السكربتات وتفعيل التايمرات بنجاح!"

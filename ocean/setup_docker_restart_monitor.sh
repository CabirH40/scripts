#!/bin/bash

# تحميل السكربتات من GitHub
curl -o /root/disk_watcher.sh https://raw.githubusercontent.com/CabirH40/script.sh/main/ocean/disk_watcher.sh
curl -o /root/restart_docker.sh https://raw.githubusercontent.com/CabirH40/script.sh/main/ocean/restart_docker.sh

# إعطاء صلاحيات التنفيذ
chmod +x /root/disk_watcher.sh
chmod +x /root/restart_docker.sh

# إنشاء خدمة disk-watcher
cat <<EOF > /etc/systemd/system/disk-watcher.service
[Unit]
Description=Disk Usage Watcher
After=network.target

[Service]
ExecStart=/bin/bash /root/disk_watcher.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# إنشاء خدمة restart-docker
cat <<EOF > /etc/systemd/system/restart-docker.service
[Unit]
Description=Restart Docker Containers After Reboot
After=network.target docker.service
Requires=docker.service

[Service]
ExecStart=/bin/bash /root/restart_docker.sh
Type=simple
User=root
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# إعادة تحميل وتعريف الخدمات
systemctl daemon-reexec
systemctl daemon-reload

# تفعيل وتشغيل الخدمات
systemctl enable disk-watcher.service
systemctl start disk-watcher.service
systemctl enable restart-docker.service

echo "✅ تم التثبيت والتشغيل بنجاح."

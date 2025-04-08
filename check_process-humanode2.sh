# تحميل سكربت Python
wget https://github.com/CabirH40/script.sh/raw/main/check_process-humanode.py -O /root/check_process-humanode.py && chmod +x /root/check_process-humanode.py

# إنشاء ملف الخدمة
cat <<EOF > /etc/systemd/system/check_process-humanode.service
[Unit]
Description=Humanode Process Checker
After=network.target

[Service]
ExecStart=/usr/bin/python3 /root/check_process-humanode.py
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

# تفعيل وتشغيل الخدمة
sudo systemctl daemon-reload
sudo systemctl enable check_process-humanode.service
sudo systemctl start check_process-humanode.service
sudo systemctl status check_process-humanode.service

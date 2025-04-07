wget https://github.com/CabirH40/script.sh/raw/main/check_process-humanode.sh -O /root/check_process-humanode.sh && chmod ug+x /root/check_process-humanode.sh
chmod +x /root/check_process-humanode.sh
[Unit]
Description=Humanode Process Checker
After=network.target

[Service]
ExecStart=/bin/bash /root/check_process-humanode.sh
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
sudo systemctl daemon-reload
sudo systemctl enable check_process-humanode.service
sudo systemctl start check_process-humanode.service
sudo systemctl status check_process-humanode.service

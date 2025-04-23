#!/bin/bash

# إنشاء سكربت التشغيل داخل مجلد العمل
cat <<EOF | sudo tee /root/.humanode/workspaces/default/start-humanode-peer.sh
#!/bin/bash
cd /root/.humanode/workspaces/default
NAME=\$(jq -r '.nodename' workspace.json)
./humanode-peer \\
  --base-path substrate-data \\
  --name "\$NAME" \\
  --validator \\
  --chain chainspec.json \\
  --rpc-url-ngrok-detect \\
  --rpc-cors all
EOF

# جعل السكربت قابل للتنفيذ
sudo chmod +x /root/.humanode/workspaces/default/start-humanode-peer.sh

# إعداد خدمة systemd
cat <<EOF | sudo tee /etc/systemd/system/humanode-peer.service
[Unit]
Description=Humanode Peer Service
After=network.target

[Service]
WorkingDirectory=/root/.humanode/workspaces/default
ExecStart=/root/.humanode/workspaces/default/start-humanode-peer.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# تفعيل الخدمة
sudo systemctl daemon-reload
sudo systemctl enable --now humanode-peer.service

echo "✅ تم إنشاء السكربت والخدمة بنجاح!"

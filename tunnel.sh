#!/bin/bash

cat <<EOF | sudo tee /etc/systemd/system/humanode-tunnel.service
[Unit]
Description=Humanode WebSocket Tunnel
After=network.target

[Service]
WorkingDirectory=/root/.humanode/workspaces/default
ExecStart=/usr/bin/env bash -c 'TARGET_URL="ws://127.0.0.1:9944" ./humanode-websocket-tunnel'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now humanode-tunnel.service

echo "✅ تم إنشاء وتشغيل خدمة Humanode Tunnel بنجاح."

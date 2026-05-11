#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

echo "🚀 بدء إنشاء خدمات Humanode Tunnel للنودات..."

# 1. خدمة الروت
cat <<EOF > /etc/systemd/system/humanode-tunnel-root.service
[Unit]
Description=Humanode WebSocket Tunnel - Root Node
After=network.target

[Service]
WorkingDirectory=/root/.humanode/workspaces/default
ExecStart=/usr/bin/env bash -c 'TARGET_URL="ws://127.0.0.1:9944" ./humanode-websocket-tunnel'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "✅ تم إنشاء خدمة: humanode-tunnel-root"

# 2. خدمات node1 إلى node11
for i in {1..11}; do
  node_dir="/home/node$i/.humanode/workspaces/default"
  rpc_port=$((9944 + i))  # node1 = 9945, node2 = 9946, ...
  service_name="humanode-tunnel-node$i"
  if [[ ! -d "$node_dir" ]]; then
    echo "⚠️ Directory not found: $node_dir, skipping $service_name"
    continue
  fi

  cat <<EOF > /etc/systemd/system/${service_name}.service
[Unit]
Description=Humanode WebSocket Tunnel - Node $i
After=network.target

[Service]
WorkingDirectory=$node_dir
ExecStart=/usr/bin/env bash -c 'TARGET_URL="ws://127.0.0.1:$rpc_port" ./humanode-websocket-tunnel'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  echo "✅ تم إنشاء خدمة: ${service_name}"

done

# تحديث systemd وتشغيل كل الخدمات
systemctl daemon-reload

# تشغيل خدمة الروت
systemctl enable --now humanode-tunnel-root.service

# تشغيل باقي الخدمات
for i in {1..11}; do
  if [[ -f "/etc/systemd/system/humanode-tunnel-node$i.service" ]]; then
    systemctl enable --now humanode-tunnel-node$i.service
  fi
done

echo "✅ تم تشغيل جميع خدمات Humanode Tunnel (root + node1-11) بنجاح."

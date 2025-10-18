#!/bin/bash
# سكربت لإنشاء ملفات run-node.sh لعقد Humanode (root و node1..node9)

# 1. إنشاء ملف run-node.sh للمستخدم root
cat > /root/.humanode/workspaces/default/run-node.sh << 'EOF'
#!/bin/bash
cd /root/.humanode/workspaces/default
NAME=$(jq -r '.nodename' workspace.json)
./humanode-peer \
  --base-path substrate-data \
  --name "$NAME" \
  --validator \
  --chain chainspec.json \
  --rpc-url-ngrok-detect \
  --rpc-cors all \
  --port 30334 \
  --rpc-port 9944 \
  --unsafe-rpc-external \
  --rpc-methods=unsafe
EOF

# جعل الملف قابلاً للتنفيذ
chmod +x /root/.humanode/workspaces/default/run-node.sh

# 2. إنشاء ملفات run-node.sh للمستخدمين node1 إلى node9
for i in {1..11}; do
  NODE_HOME="/home/node$i/.humanode/workspaces/default"
  cat > "$NODE_HOME/run-node.sh" << EOF
#!/bin/bash
cd $NODE_HOME
NAME=\$(jq -r '.nodename' workspace.json)
./humanode-peer \\
  --base-path substrate-data \\
  --name "\$NAME" \\
  --validator \\
  --chain chainspec.json \\
  --rpc-url-ngrok-detect \\
  --rpc-cors all \\
  --port $((30334 + i)) \\
  --rpc-port $((9944 + i)) \\
  --unsafe-rpc-external \\
  --rpc-methods=unsafe
EOF

  # جعل الملف قابلاً للتنفيذ لكل عقدة
  chmod +x "$NODE_HOME/run-node.sh"
done

echo "تم إنشاء ملفات run-node.sh لجميع العقد (root و node1-node9) بنجاح."

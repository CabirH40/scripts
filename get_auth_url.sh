#!/bin/bash
set -euo pipefail

WORKSPACE_FILE="/root/.humanode/workspaces/default/workspace.json"
CHAINSPEC="/root/.humanode/workspaces/default/chainspec.json"
PEER_BIN="/root/.humanode/workspaces/default/humanode-peer"
WEBSITE_DIR="/root/script/website"
OUTPUT_HTML="${WEBSITE_DIR}/index.html"
RPC_URL="http://127.0.0.1:9944"

mkdir -p "$WEBSITE_DIR"

node_name="$(jq -r '.nodename // "Unknown Node"' "$WORKSPACE_FILE" 2>/dev/null || echo "Unknown Node")"
auth_url="Unavailable"
status_json="$(curl -s --max-time 8 "$RPC_URL" -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' || true)"

if [ -x "$PEER_BIN" ] && [ -f "$CHAINSPEC" ]; then
  auth_url="$(timeout 20 "$PEER_BIN" bioauth auth-url --rpc-url-ngrok-detect --chain "$CHAINSPEC" 2>/dev/null || echo "Unavailable")"
fi

expires_at_ms="$(echo "$status_json" | jq -r '.result.Active.expires_at // 0' 2>/dev/null || echo 0)"
if ! [[ "$expires_at_ms" =~ ^[0-9]+$ ]]; then
  expires_at_ms=0
fi

now_ts="$(date +%s)"
expires_at_s=$((expires_at_ms / 1000))
remaining_s=$((expires_at_s - now_ts))
if (( remaining_s < 0 )); then
  remaining_s=0
fi

days=$((remaining_s / 86400))
hours=$(((remaining_s % 86400) / 3600))
minutes=$(((remaining_s % 3600) / 60))

if (( expires_at_s > 0 )); then
  end_time="$(date -d "@$expires_at_s" '+%Y-%m-%d %H:%M:%S')"
else
  end_time="N/A"
fi

cat > "$OUTPUT_HTML" <<EOF
<!DOCTYPE html>
<html lang="ar">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Humanode</title>
  <style>
    body { font-family: Arial, sans-serif; background:#111; color:#fff; text-align:center; padding:20px; }
    .box { max-width: 820px; margin: 0 auto; background:#1d1d1d; border-radius:12px; padding:20px; }
    a { display:inline-block; margin-top:16px; padding:10px 16px; background:#2e7d32; color:#fff; text-decoration:none; border-radius:8px; }
    .warn { color:#ff7043; }
  </style>
</head>
<body>
  <div class="box">
    <h1>مرحبًا بك في صفحة الهومانود</h1>
    <p>اسم العقدة: ${node_name}</p>
    <p>الوقت المتبقي: ${days} يوم ${hours} ساعة ${minutes} دقيقة</p>
    <p>وقت انتهاء التوثيق: ${end_time}</p>
    <p class="warn">يتم تحديث هذه الصفحة تلقائيًا كل دقيقة.</p>
    <a href="${auth_url}" target="_blank" rel="noopener noreferrer">اذهب إلى رابط التوثيق</a>
  </div>
</body>
</html>
EOF

chmod 644 "$OUTPUT_HTML"

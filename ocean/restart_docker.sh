#!/bin/bash

BOT_TOKEN="8156961663:AAGAETb8hWNukSsLoTViw12bb70QrMQs8xE"
CHAT_ID="-1002493763559"



send_alert() {
  local MESSAGE="$1"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" -d text="$MESSAGE"
}

# جلب عنوان IP العام
PUBLIC_IP=$(curl -s https://ipinfo.io/ip)

# رسالة البدء
if [ -f /tmp/trigger_docker_restart ]; then
    rm /tmp/trigger_docker_restart
    send_alert "🌍 IP: $PUBLIC_IP\n🔁 النظام أقلع بعد امتلاء القرص. جاري إعادة تشغيل حاويات Docker..."
else
    send_alert "🌍 IP: $PUBLIC_IP\n🔁 النظام أقلع (إقلاع عادي). جاري إعادة تشغيل حاويات Docker..."
fi

# إعادة تشغيل الحاويات
COUNT=0
for dir in ~/docker-compose-files/node-*; do
  if [ -f "$dir/docker-compose.yml" ]; then
    docker compose -f "$dir/docker-compose.yml" restart >/dev/null 2>&1
    COUNT=$((COUNT + 1))
  fi
done

# رسالة النهاية
send_alert "✅ تم إعادة تشغيل $COUNT حاوية Docker بنجاح.\n🌍 IP: $PUBLIC_IP"

# إعادة تشغيل مراقبة القرص

#!/bin/bash

BOT_TOKEN="8156961663:AAGAETb8hWNukSsLoTViw12bb70QrMQs8xE"
CHAT_ID="-1002493763559"


send_alert() {
  local MESSAGE="$1"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" -d text="$MESSAGE"
}

if [ -f /tmp/trigger_docker_restart ]; then
    rm /tmp/trigger_docker_restart
    send_alert "🔁 النظام أقلع مجددًا بعد امتلاء القرص. جاري إعادة تشغيل الحاويات..."
else
    send_alert "ℹ️ تم تشغيل النظام مجددًا (إقلاع عادي). سيتم إعادة تشغيل الحاويات كإجراء تلقائي."
fi

for dir in ~/docker-compose-files/node-*; do
  if [ -f "$dir/docker-compose.yml" ]; then
    send_alert "🔄 إعادة تشغيل الحاويات في $dir"
    docker compose -f "$dir/docker-compose.yml" restart
  else
    send_alert "⚠️ لم يتم العثور على docker-compose.yml في $dir — تم التخطي."
  fi
done

send_alert "✅ جميع الحاويات أعيد تشغيلها. سيُعاد تفعيل مراقبة القرص الآن."
nohup /root/disk_watcher.sh &

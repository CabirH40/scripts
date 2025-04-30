#!/bin/bash

PARTITION="/dev/sda2"
THRESHOLD=98.0  # ✅ الحد الجديد: 98%
SCRIPT_TO_RUN="/root/restart_docker.sh"

# إعدادات تيليجرام
BOT_TOKEN="8156961663:AAGAETb8hWNukSsLoTViw12bb70QrMQs8xE"
CHAT_ID="-1002493763559"

send_alert() {
  MESSAGE=$1
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" -d text="$MESSAGE"
}

check_disk_usage() {
    USAGE=$(df -h "$PARTITION" | awk 'NR==2 {gsub("%",""); print $5}')
    USAGE_FLOAT=$(echo "$USAGE" | awk '{printf "%.1f", $1}')
    PUBLIC_IP=$(curl -s https://ipinfo.io/ip)
    echo "🔍 الاستخدام الحالي: $USAGE_FLOAT%"

    RESULT=$(echo "$USAGE_FLOAT > $THRESHOLD" | bc)
    if [ "$RESULT" -eq 1 ]; then
        send_alert "🚨 السيرفر ممتلئ بنسبة $USAGE_FLOAT%\n🌍 IP: $PUBLIC_IP\n📦 القسم: $PARTITION\n🔁 سيتم إعادة تشغيل النظام الآن!"
        touch /tmp/trigger_docker_restart
        reboot
    fi
}

while true; do
    check_disk_usage
    sleep 300
done

#!/bin/bash

# إعداد المتغيرات
TELEGRAM_TOKEN="6771313174:AAGSrlGl7LnJg1ewGlaS6QO5fpL5OVXJNWg"
CHAT_ID="-1002493763559"

# جلب الـ IP العام للسيرفر
SERVER_IP=$(curl -s ifconfig.me)
NODE_URL="http://$SERVER_IP:8000/dashboard"

# وظيفة لإرسال رسالة إلى تليغرام
send_telegram_message() {
    MESSAGE=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$MESSAGE"
}

# فحص حالة الن
check_node() {
    CONTENT=$(curl -s "$NODE_URL")
    if [ -z "$CONTENT" ]; then
        send_telegram_message "⚠️ Ocean Node is down! Unable to load content from $NODE_URL"
    
    fi
}


# استدعاء الدالة
check_node

#!/bin/bash

# Telegram bot details
telegram_token='YOUR_TELEGRAM_TOKEN'
telegram_group='YOUR_TELEGRAM_GROUP'
telegram_user_tag="@CabirH2000 @testnetsever"

# Script starts here
server_ip=$(curl -s https://api.ipify.org)
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

# استبدل بـ API URL المناسب
api_url="http://127.0.0.1:9933" 

# استعلام للحصول على حالة الـ API
status=$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' "${api_url}")

# استخراج وقت البدء (استبدل `.start_time` بالمفتاح الصحيح)
start_time=$(echo "$status" | jq -r '.start_time') 

# تحقق مما إذا كان start_time موجودًا
if [ -n "$start_time" ]; then
    # تحويل وقت البدء إلى تنسيق سهل الفهم (توقيت تركيا)
    formatted_time=$(date -d "@$start_time" +"%H:%M %Z")
    start_time_message="📸 يجب أن يبدأ التصوير الساعة ${formatted_time} بتوقيت تركيا."
    
    # إرسال رسالة إلى Telegram
    curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${start_time_message}" ${telegram_bot}
else
    start_time_message="⚠️ لم يتم العثور على وقت البدء."
    curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${start_time_message}" ${telegram_bot}
fi

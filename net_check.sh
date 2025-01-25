#!/bin/bash

# إعداد متغيرات
TELEGRAM_TOKEN="7019470192:AAE2KwDnCIaVTS9tp19mfLCGSst-8FPNr04"
CHAT_ID="-1002175706144"
CHECK_INTERVAL=5  # فحص الاتصال كل 5 ثواني
TIMEOUT=30  # الزمن المسموح به لانقطاع الاتصال (30 ثانية)

# دالة لإرسال رسالة إلى التلغرام
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
         -d chat_id=$CHAT_ID \
         -d text="$message"
}

# دالة لفحص الاتصال بالإنترنت
check_internet() {
    ping -c 1 google.com &> /dev/null
    return $?
}

# متغيرات لتخزين الحالة
internet_down_time=0
internet_was_down=0  # لتحديد ما إذا كان الإنترنت قد انقطع سابقًا

while true; do
    if check_internet; then
        # إذا عاد الإنترنت بعد انقطاعه
        if [ $internet_was_down -eq 1 ]; then
            send_telegram_message "انقطاع الإنترنت تم معالجته. يرجى فحص الاتصال."
            internet_was_down=0  # إعادة تعيين الحالة
        fi
        # إعادة تعيين الوقت إذا كان الإنترنت متاحًا
        internet_down_time=0
    else
        # إذا انقطع الإنترنت، نزيد الوقت
        ((internet_down_time+=CHECK_INTERVAL))
        
        # إذا انقطع الإنترنت لمدة 30 ثانية، نعلم بأنه تم الانقطاع
        if [ $internet_down_time -ge $TIMEOUT ] && [ $internet_was_down -eq 0 ]; then
            internet_was_down=1
        fi
    fi

    # الانتظار قبل إعادة الفحص
    sleep $CHECK_INTERVAL
done

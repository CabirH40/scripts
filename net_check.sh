#!/bin/bash

SCRIPT_PATH="/root/internet_watchdog.sh"
SERVICE_NAME="internet-watchdog.service"

# ✅ التحقق إذا كانت الخدمة مفعلة والسكريبت موجود
if systemctl is-enabled --quiet "$SERVICE_NAME" && [ -f "$SCRIPT_PATH" ]; then
    echo "✅ الخدمة $SERVICE_NAME موجودة وفعالة. يتم التخطي."
    exit 0
fi

echo "📦 جاري تثبيت خدمة مراقبة الاتصال بالإنترنت..."

# ✅ إنشاء سكربت المراقبة
cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash

# إعداد متغيرات
TELEGRAM_TOKEN="7019470192:AAE2KwDnCIaVTS9tp19mfLCGSst-8FPNr04"
CHAT_ID="-1002175706144"
CHECK_INTERVAL=5  # فحص الاتصال كل 5 ثواني
TIMEOUT=30        # الزمن المسموح به لانقطاع الاتصال (30 ثانية)

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
internet_was_down=0

while true; do
    if check_internet; then
        if [ $internet_was_down -eq 1 ]; then
            send_telegram_message "✅ تم استعادة الاتصال بالإنترنت."
            internet_was_down=0
        fi
        internet_down_time=0
    else
        ((internet_down_time+=CHECK_INTERVAL))
        if [ $internet_down_time -ge $TIMEOUT ] && [ $internet_was_down -eq 0 ]; then
            send_telegram_message "🚫 انقطاع في الإنترنت لمدة ${TIMEOUT} ثانية!"
            internet_was_down=1
        fi
    fi
    sleep $CHECK_INTERVAL
done
EOF

chmod +x "$SCRIPT_PATH"

# ✅ إنشاء ملف خدمة systemd
cat << EOF > "/etc/systemd/system/$SERVICE_NAME"
[Unit]
Description=Internet Watchdog - Telegram Notifier
After=network.target

[Service]
ExecStart=$SCRIPT_PATH
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# ✅ تفعيل وتشغيل الخدمة
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

echo "✅ تم تثبيت وتفعيل الخدمة $SERVICE_NAME بنجاح."
exit

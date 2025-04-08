#!/bin/bash

SERVICE_NAME="check_process-humanode.service"
SCRIPT_PATH="/root/check_process-humanode.sh"
PYTHON_SCRIPT="/root/check_process-humanode.py"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

echo "🛑 إيقاف الخدمة إن وُجدت..."
systemctl stop "$SERVICE_NAME"

echo "🧹 حذف ملف الخدمة..."
rm -f "$SERVICE_FILE"

echo "🔄 إعادة تحميل systemd..."
systemctl daemon-reload

echo "❌ حذف سكربت bash إن وُجد..."
rm -f "$SCRIPT_PATH"

echo "❌ حذف سكربت python إن وُجد..."
rm -f "$PYTHON_SCRIPT"

echo "✅ تم حذف كل شيء متعلق بـ $SERVICE_NAME"

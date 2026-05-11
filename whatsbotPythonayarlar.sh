#!/bin/bash
set -euo pipefail

# تحديث الحزم
echo "🔄 تحديث قائمة الحزم..."
apt update -y

# التحقق من وجود Python 3
if command -v python3 >/dev/null 2>&1; then
    echo "✅ Python 3 مثبت مسبقًا."
else
    echo "📦 Python 3 غير موجود، يتم التثبيت..."
    apt install python3 -y
fi

# التحقق من وجود pip3
if command -v pip3 >/dev/null 2>&1; then
    echo "✅ pip3 مثبت مسبقًا."
else
    echo "📦 pip3 غير موجود، يتم التثبيت..."
    apt install python3-pip -y
fi

# التحقق من وجود مكتبات Python المطلوبة
echo "🔍 التحقق من مكتبات Python المطلوبة..."

for package in paramiko schedule requests pytz; do
    if python3 -c "import $package" >/dev/null 2>&1; then
        echo "✅ المكتبة $package مثبتة."
    else
        echo "📦 تثبيت المكتبة $package باستخدام --break-system-packages..."
        pip3 install "$package" --break-system-packages --no-cache-dir
    fi
done

# 🧹 تنظيف سجل اللوجات
> /root/.humanode/workspaces/default/node/logs.txt

echo "🎉 تم التحقق من جميع المتطلبات وتثبيت المكتبات بنجاح."

exit

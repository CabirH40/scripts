#!/bin/bash

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

# التحقق من وجود المكتبات المطلوبة
echo "🔍 التحقق من المكتبات Python المطلوبة..."

for package in paramiko schedule requests pytz; do
    if python3 -c "import $package" >/dev/null 2>&1; then
        echo "✅ المكتبة $package مثبتة."
    else
        echo "📦 تثبيت المكتبة $package..."
        pip3 install "$package"
    fi
done

echo "🎉 تم التحقق من جميع المتطلبات."
exit
# إفراغ ملف logs.txt
> /root/.humanode/workspaces/default/node/logs.txt


# إنهاء السكربت بعد تنفيذ الأوامر
exit
#for error solvied 
#sudo apt remove --purge python3 python3-pip python3-venv python3-setuptools python3-wheel -y
#sudo apt autoremove -y
#sudo rm -rf /usr/lib/python3* /usr/local/lib/python3* ~/.local/lib/python3* ~/.cache/pip
#sudo apt update && sudo apt install python3 python3-pip python3-venv python3-setuptools python3-wheel libssl-dev -y
#pip3 install --no-cache-dir requests urllib3 cryptography pyOpenSSL paramiko schedule pytz
#python3 whatsbot.py

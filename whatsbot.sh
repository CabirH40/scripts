#!/bin/bash

# تحديث الحزم
apt update -y

# تثبيت Python 3 و pip3 إذا لم يكن مثبتًا
apt install python3 python3-pip -y

# تثبيت مكتبات paramiko و schedule
pip3 install paramiko schedule

# إفراغ ملف logs.txt
> .humanode/workspaces/default/node/logs.txt

# تنفيذ الأمر لإنشاء جلسة screen وتشغيل السكريبت
screen -dmS whatsbot
screen -S whatsbot -X stuff $'wget https://raw.githubusercontent.com/CabirH40/script.sh/main/whatsbot.py -O whatsbot.py && python3 whatsbot.py\n'

# إنهاء السكريبت بعد تنفيذ الأوامر
exit

#!/bin/bash

# تحديث الحزم
apt update -y

# تثبيت Python 3 و pip3 إذا لم يكن مثبتًا
apt install python3 python3-pip -y

# تثبيت مكتبات paramiko, schedule, requests و pytz
pip3 install paramiko schedule requests pytz

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

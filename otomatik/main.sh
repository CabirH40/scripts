#!/bin/bash

# 🛠️ 1) إنشاء مجلدات


# 🖥️ 2) تحميل السكربتات داخل /root/script
cd /root/script
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/caddy.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/checkpeer.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/peer.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/port-ayar.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/script.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/whatsbotservis.sh

# 🏃‍♂️ 3) تشغيل سكربتات مرة واحدة
bash caddy.sh
bash checkpeer.sh
bash peer.sh
bash port-ayar.sh




echo "✅ العملية تمت بنجاح: السكربتات جاهزة ومجلدات منظمة."

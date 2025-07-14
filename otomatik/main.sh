#!/bin/bash

# 🛠️ 1) إنشاء مجلدات
mkdir -p /root/script
for i in {1..9}; do
  mkdir -p "/root/script/node$i"
done

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

# 📂 4) نقل الواتس الى مجلد whatsapp-bot
mkdir -p /root/script/whatsapp-bot
mv whatsbotservis.sh /root/script/whatsapp-bot/

# 🔁 5) تجهيز مجلدات النودات مع السكربتات
for i in {1..9}; do
  cp script.sh "/root/script/node$i/"
  mkdir -p "/root/script/node$i/whatsapp-bot"
  cp /root/script/whatsapp-bot/whatsbotservis.sh "/root/script/node$i/whatsapp-bot/"
done

echo "✅ العملية تمت بنجاح: السكربتات جاهزة ومجلدات منظمة."

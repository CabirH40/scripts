#!/bin/bash

# 🧑‍💻 1) إنشاء المستخدمين وإعطاؤهم الصلاحيات
for i in {1..11}; do
  username="node$i"
  sudo useradd -m -s /bin/bash "$username"
  echo "$username:4Y8z1eblEJ" | sudo chpasswd
  sudo usermod -aG sudo "$username"
done

# 📁 2) نسخ مجلد .humanode إلى كل مستخدم وتعديل الصلاحيات
for i in {1..11}; do
  username="node$i"
  sudo cp -r /root/.humanode /home/$username/
  sudo chown -R $username:$username /home/$username/.humanode
done

# 🛠️ 3) التأكد من وجود مجلد /root/script
mkdir -p /root/script
cd /root/script || exit 1

# 🖥️ 4) تحميل السكربتات من GitHub
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/caddy.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/checkpeer.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/peer.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/port-ayar.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/script.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/whatsbotservis.sh
wget -q https://raw.githubusercontent.com/CabirH40/scripts/main/otomatik/configure_nodes.sh

# 🏃‍♂️ 5) تشغيل السكربتات مرة واحدة (تأكد أنها قابلة للتنفيذ)
chmod +x *.sh
./caddy.sh
./checkpeer.sh
./peer.sh
./port-ayar.sh
./whatsbotservis.sh
./configure_nodes.sh

echo "✅ العملية تمت بنجاح: المستخدمين تم إنشاؤهم والسكربتات تم تحميلها وتشغيلها."

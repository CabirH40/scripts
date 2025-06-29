#!/bin/bash

echo "بدء تثبيت الهوما نود..."



# الخطوة 2: تثبيت humanode-launcher
echo "تثبيت apt-transport-https وإضافة مستودع humanode-launcher..."
sudo apt-get install -y apt-transport-https
echo "deb [trusted=yes] https://stable.apt.launcher.humanode.io ./" | sudo tee /etc/apt/sources.list.d/humanode-launcher-stable.list
sudo apt-get update
sudo apt-get install -y humanode-launcher

# الخطوة 3: إعداد Swap
echo "إعداد Swap..."
sudo dd if=/dev/zero of=/root/swapfile bs=1G count=1
sudo chmod 600 /root/swapfile
ls -lh /root/swapfile
sudo mkswap /root/swapfile
sudo swapon /root/swapfile
free -h

# الخطوة 4: تعديل /etc/fstab
echo "تعديل /etc/fstab لإضافة swap..."
echo "/root/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab

# الخطوة 5: تشغيل humanode-launcher
echo "تشغيل humanode-launcher..."
#humanode-launcher --no-sandbox

echo "تم الانتهاء من التثبيت والتشغيل بنجاح!"

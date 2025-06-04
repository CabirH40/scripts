#!/bin/bash

echo "🚀 بدء عملية التنظيف الشامل... (By Abu Jaber 💪)"
sleep 1

### 1️⃣ تنظيف apt cache
echo "🧹 تنظيف apt cache..."
sudo apt clean
sudo rm -rf /var/cache/*

### 2️⃣ تنظيف log files
echo "🧹 تنظيف log files..."
sudo journalctl --vacuum-time=2d
sudo find /var/log -type f -name "*.gz" -delete
sudo find /var/log -type f -name "*.1" -delete
sudo find /var/log -type f -size +10M -exec truncate -s 0 {} \;

### 3️⃣ تنظيف /var/tmp
echo "🧹 تنظيف /var/tmp..."
sudo rm -rf /var/tmp/*

### 4️⃣ تنظيف snap الإصدارات القديمة فقط (core محمي)
echo "🧹 تنظيف snap المعطلة فقط..."
snap list --all | awk '/disabled/{print $1, $3}' | while read name rev; do
  echo "❌ Removing old snap: $name revision $rev"
  sudo snap remove "$name" --revision="$rev"
done

### 5️⃣ تنظيف Docker
if command -v docker &> /dev/null; then
  echo "🧹 تنظيف Docker..."
  docker system prune -a --volumes -f
else
  echo "ℹ️ Docker غير مثبت – تخطيت التنظيف."
fi

### 6️⃣ تنظيف /usr/share من man, doc, info, locale
echo "🧹 تنظيف /usr/share..."
sudo rm -rf /usr/share/man/*
sudo rm -rf /usr/share/doc/*
sudo rm -rf /usr/share/info/*
sudo find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' -exec rm -rf {} +

echo "✅ تم التنظيف بنجاح! (أبو جابر style 💥)"

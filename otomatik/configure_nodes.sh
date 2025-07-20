#!/bin/bash

for i in {1..9}; do
  echo "==============================="
  echo "🔧 إعداد node$i"
  echo "==============================="

  # 👤 طلب اسم المستخدم (لتحديد مجلد /home/nodeX)
  read -p "👤 أدخل اسم المستخدم (مثلاً: node$i): " username

  # 📛 طلب اسم النود
  read -p "📛 أدخل اسم النود (بدون فراغات): " nodename

  # 📁 مسار ملف JSON
  workspace_json="/home/$username/.humanode/workspaces/default/workspace.json"

  if [[ ! -f "$workspace_json" ]]; then
    echo "❌ لم يتم العثور على workspace.json في $workspace_json"
    continue
  fi

  # 📝 تعديل اسم النود داخل ملف JSON
  sudo sed -i 's/"nodename":"[^"]*"/"nodename":"'"$nodename"'"/' "$workspace_json"
  echo "✅ تم تعديل اسم النود في $workspace_json"

  # 🔑 طلب 12 كلمة
  read -p "🧠 أدخل 12 كلمة (Mnemonic): " mnemonic

  # 🧹 حذف محتويات keystore
  keystore_path="/home/$username/.humanode/workspaces/default/substrate-data/chains/humanode_mainnet/keystore"
  if [[ -d "$keystore_path" ]]; then
    sudo rm -rf "$keystore_path"/*
    echo "🧹 تم حذف محتويات keystore"
  else
    echo "⚠️ لم يتم العثور على مجلد keystore، جاري إنشاؤه..."
    sudo mkdir -p "$keystore_path"
    sudo chown -R "$username":"$username" "$keystore_path"
  fi

  # ✅ تشغيل أمر الإدخال من داخل workspaces/default
  cd "/home/$username/.humanode/workspaces/default" || { echo "❌ لم يتم الدخول إلى مجلد العمل"; continue; }

  # 🔎 تحقق من وجود ملف التنفيذ
  if [[ ! -f "./humanode-engine" ]]; then
    echo "❌ لم يتم العثور على ./humanode-engine في مجلد default"
    continue
  fi

  # 🎯 إدخال المفتاح
  sudo -u "$username" ./humanode-engine key insert \
    --key-type kbai \
    --scheme sr25519 \
    --suri "$mnemonic" \
    --base-path substrate-data \
    --chain chainspec.json

  echo "✅ تم إدخال المفتاح بنجاح للنود $username"
  echo
done

echo "🎉 تم الانتهاء من إعداد كل النودات من node1 إلى node9!"

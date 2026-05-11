#!/bin/bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

for i in {1..11}; do
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
  sed -i 's/"nodename":"[^"]*"/"nodename":"'"$nodename"'"/' "$workspace_json"
  echo "✅ تم تعديل اسم النود في $workspace_json"

  # 🔑 طلب 12 كلمة
  read -p "🧠 أدخل 12 كلمة (Mnemonic): " mnemonic

  # 🧹 حذف محتويات keystore
  keystore_path="/home/$username/.humanode/workspaces/default/substrate-data/chains/humanode_mainnet/keystore"
  if [[ -d "$keystore_path" ]]; then
    rm -rf "$keystore_path"/*
    echo "🧹 تم حذف محتويات keystore"
  else
    echo "⚠️ لم يتم العثور على مجلد keystore، جاري إنشاؤه..."
    mkdir -p "$keystore_path"
    chown -R "$username":"$username" "$keystore_path"
  fi

  # ✅ الانتقال للمجلد الصحيح
  cd "/home/$username/.humanode/workspaces/default" || { echo "❌ لم يتم الدخول إلى مجلد default"; continue; }

  # ✅ التحقق من وجود binary
  if [[ ! -f "./humanode-peer" ]]; then
    echo "❌ لم يتم العثور على ./humanode-peer في workspaces/default"
    continue
  fi

  # 🧠 إدخال المفتاح
  runuser -u "$username" -- ./humanode-peer key insert \
    --key-type kbai \
    --scheme sr25519 \
    --suri "$mnemonic" \
    --base-path substrate-data \
    --chain chainspec.json

  echo "✅ تم إدخال المفتاح بنجاح للنود $username"
  echo
done

echo "🎉 تم الانتهاء من إعداد كل النودات من node1 إلى node11!"

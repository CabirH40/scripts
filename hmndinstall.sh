#!/bin/bash

# مسار العمل
WORKSPACE_PATH=~/.humanode/workspaces/default

# التحقق من وجود المحفظة
echo "Do you have a wallet? (yes/no)"
read answer

if [[ "$answer" == "yes" || "$answer" == "YES" || "$answer" == "y" || "$answer" == "Y" ]]; then
  # إذا كانت الإجابة نعم، يطلب إدخال الكلمات الـ12 واسم النود
  echo "Enter your 12 words (separated by space):"
  read mnemonic
  echo "Enter your node name:"
  read nodename

  # التبديل إلى المسار الصحيح
  cd $WORKSPACE_PATH

  # تنفيذ الأمر الخاص بإدخال المفتاح
  ./humanode-peer key insert --key-type kbai --scheme sr25519 --suri "$mnemonic" --base-path substrate-data --chain chainspec.json

  # تعديل ملف workspace.json باستخدام sed
  sed -i "s/\"mnemonicInserted\": false/\"mnemonicInserted\": true/" $WORKSPACE_PATH/workspace.json
  sed -i "s/\"nodename\": \"\"/\"nodename\": \"$nodename\"/" $WORKSPACE_PATH/workspace.json

  # تثبيت الأدوات المطلوبة
  sudo apt-get install aria2 -y
  sudo apt install pigz -y

  # إزالة البيانات القديمة
  rm -rf $WORKSPACE_PATH/substrate-data/chains/humanode_mainnet/db/full

  # تحميل البيانات من المصدر
  aria2c -x 16 -s 16 -o full.tar.gz http://89.116.25.136/24.01.2025/snapshot.tar.gz
  pigz -dc full.tar.gz | tar -x -C $WORKSPACE_PATH/substrate-data/chains/humanode_mainnet/db/

  echo "Process completed successfully!"
else
  # إذا لم تكن هناك محفظة، يقوم بتوليد محفظة جديدة
  echo "You don't have a wallet, one will be generated."

  # التبديل إلى المسار الصحيح
  cd $WORKSPACE_PATH

  # توليد المحفظة الجديدة
  output=$(./humanode-peer key generate)

  # استخراج الـ 12 كلمة من مخرجات الأمر
  mnemonic=$(echo "$output" | grep -oP 'Secret phrase:\s+\K.*')

  # طلب اسم النود
  echo "Enter your node name:"
  read nodename

  echo "These are your 12 words: $mnemonic"

  # تنفيذ الخطوات السابقة باستخدام الكلمات الجديدة
  ./humanode-peer key insert --key-type kbai --scheme sr25519 --suri "$mnemonic" --base-path substrate-data --chain chainspec.json

  # تعديل ملف workspace.json باستخدام sed
  sed -i "s/\"mnemonicInserted\": false/\"mnemonicInserted\": true/" $WORKSPACE_PATH/workspace.json
  sed -i "s/\"nodename\": \"\"/\"nodename\": \"$nodename\"/" $WORKSPACE_PATH/workspace.json

  # تثبيت الأدوات المطلوبة
  sudo apt-get install aria2 -y
  sudo apt install pigz -y

  # إزالة البيانات القديمة
  rm -rf $WORKSPACE_PATH/substrate-data/chains/humanode_mainnet/db/full

  # تحميل البيانات من المصدر
  aria2c -x 16 -s 16 -o full.tar.gz http://89.116.25.136/24.01.2025/snapshot.tar.gz
  pigz -dc full.tar.gz | tar -x -C $WORKSPACE_PATH/substrate-data/chains/humanode_mainnet/db/

  echo "Process completed successfully!"
fi

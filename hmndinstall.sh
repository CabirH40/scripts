#!/bin/bash

# مسار العمل
WORKSPACE_PATH=~/.humanode/workspaces/default

# التحقق من وجود المحفظة
echo "هل لديك محفظة؟ (نعم/لا)"
read answer

if [[ "$answer" == "نعم" || "$answer" == "نعم" ]]; then
  # إذا كانت الإجابة نعم، يطلب إدخال الكلمات الـ12 واسم النود
  echo "أدخل الـ 12 كلمة الخاصة بك (مسافة بين الكلمات):"
  read mnemonic
  echo "أدخل اسم النود الخاص بك:"
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

  echo "تمت العملية بنجاح!"
else
  # إذا لم تكن هناك محفظة، يقوم بتوليد محفظة جديدة
  echo "ليس لديك محفظة، سيتم توليد واحدة جديدة."
  
  # التبديل إلى المسار الصحيح
  cd $WORKSPACE_PATH
  
  # توليد المحفظة الجديدة
  output=$(./humanode-peer key generate)

  # استخراج الـ 12 كلمة من مخرجات الأمر
  mnemonic=$(echo "$output" | grep -oP 'Secret phrase:\s+\K.*')

  # طلب اسم النود
  echo "أدخل اسم النود الخاص بك:"
  read nodename

  echo "هذه هي الكلمات الـ 12 الخاصة بك: $mnemonic"

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

  echo "تمت العملية بنجاح!"
fi

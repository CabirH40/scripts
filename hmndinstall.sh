#!/bin/bash

# مسار العمل
WORKSPACE_PATH=/root/.humanode/workspaces/default
HUMANODE_PEER_PATH=$WORKSPACE_PATH/humanode-peer  # المسار الكامل للـ humanode-peer

# التحقق من وجود المحفظة
if [ -f "$WORKSPACE_PATH/key" ]; then
  echo "هل لديك محفظة؟ (نعم/لا)"
  read answer
  if [[ "$answer" == "نعم" || "$answer" == "نعم" ]]; then
    # إذا كانت الإجابة نعم، يطلب إدخال الكلمات الـ12 واسم النود
    echo "أدخل الـ 12 كلمة الخاصة بك (مسافة بين الكلمات):"
    read mnemonic
    echo "أدخل اسم النود الخاص بك:"
    read nodename

    # الانتقال إلى المسار المطلوب
    cd $WORKSPACE_PATH

    # تنفيذ الأمر الخاص بإدخال المفتاح
    $HUMANODE_PEER_PATH key insert --key-type kbai --scheme sr25519 --suri "$mnemonic" --base-path substrate-data --chain chainspec.json

    # فتح الملف workspace.json وتعديله
    nano $WORKSPACE_PATH/workspace.json

    # تعديل ملف workspace.json يدويًا بعد حفظه
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
else
  # إذا لم تكن هناك محفظة، يقوم بتوليد محفظة جديدة
  echo "ليس لديك محفظة، سيتم توليد واحدة جديدة."

  # الانتقال إلى المسار المطلوب
  cd $WORKSPACE_PATH

  output=$($HUMANODE_PEER_PATH key generate)

  # استخراج الـ 12 كلمة من مخرجات الأمر
  mnemonic=$(echo "$output" | grep -oP 'Secret phrase:\s+\K.*')

  # طلب اسم النود
  echo "أدخل اسم النود الخاص بك:"
  read nodename

  echo "هذه هي الكلمات الـ 12 الخاصة بك: $mnemonic"

  # تنفيذ الخطوات السابقة باستخدام الكلمات الجديدة
  $HUMANODE_PEER_PATH key insert --key-type kbai --scheme sr25519 --suri "$mnemonic" --base-path substrate-data --chain chainspec.json
  nano $WORKSPACE_PATH/workspace.json

  sed -i "s/\"mnemonicInserted\": false/\"mnemonicInserted\": true/" $WORKSPACE_PATH/workspace.json
  sed -i "s/\"nodename\": \"\"/\"nodename\": \"$nodename\"/" $WORKSPACE_PATH/workspace.json

  sudo apt-get install aria2 -y
  sudo apt install pigz -y

  rm -rf $WORKSPACE_PATH/substrate-data/chains/humanode_mainnet/db/full
  aria2c -x 16 -s 16 -o full.tar.gz http://89.116.25.136/24.01.2025/snapshot.tar.gz
  pigz -dc full.tar.gz | tar -x -C $WORKSPACE_PATH/substrate-data/chains/humanode_mainnet/db/

  echo "تمت العملية بنجاح!"
fi

#!/bin/bash

# --- الخطوة 0: تثبيت Docker وتكوين الشبكة ---
echo "جاري تثبيت Docker ..."
sudo bash -c "$(curl -s https://get.docker.com)"

echo "تعديل إعدادات Docker لتفادي مشاكل الشبكة ..."
sudo bash -c 'cat > /etc/docker/daemon.json <<EOF
{
  "default-address-pools": [
    {
      "base": "10.0.0.0/8",
      "size": 24
    }
  ]
}
EOF'

echo "إعادة تشغيل Docker لتطبيق الإعدادات ..."
sudo systemctl restart docker
# --- الخطوة 0.1: تنزيل الصور المطلوبة ---
echo "جاري تنزيل صور Docker ..."
sudo docker pull typesense/typesense:26.0
sudo docker pull oceanprotocol/ocean-node:latest

echo "تعديل إعدادات DNS ..."
sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF'

echo "إعادة تشغيل systemd-resolved ..."
sudo systemctl restart systemd-resolved

# --- الخطوة 1: سؤال المستخدم عن عدد العقد ---
read -p "كم نود تريد أن تستخدم؟ " key_count

# التحقق من أن المدخل رقم صحيح
if ! [[ "$key_count" =~ ^[0-9]+$ ]] || [ "$key_count" -le 0 ]; then
    echo "خطأ: يرجى إدخال رقم صحيح أكبر من الصفر."
    exit 1
fi

# --- الخطوة 2: إنشاء المفاتيح ---
output_file="prv.txt"
> "$output_file"  # مسح الملف إذا كان موجودًا

echo "جاري إنشاء $key_count مفتاحًا ..."

for ((i=1; i<=key_count; i++)); do
    # إنشاء مفتاح عشوائي باستخدام openssl
    prv_key="0x$(openssl rand -hex 32)"
    echo "$prv_key" >> "$output_file"
done

echo "تم إنشاء $key_count مفتاحًا وحفظها في $output_file بنجاح."

# --- الخطوة 3: إنشاء ملفات النودات وتعديل المنافذ ---
KEYS_FILE="prv.txt"
BASE_IP=$(curl -s ifconfig.me)  # جلب عنوان الـ IP العام تلقائيًا
BASE_PORT=10000  # بدء البورتات من 10000
TYPESENSE_PORT=9000  # بدء بورتات typesense من 9000
ADMIN_ADDRESS="0x0CB4d01ef8534E132f1f7fa86385B9D30733dab4"  # عنوان المحفظة ثابت

i=0  # رقم العقدة
j=8000
last_used_port=1025  # بدء البورتات من 1025

# التأكد من وجود ملف المفاتيح
if [[ ! -f "$KEYS_FILE" ]]; then
    echo "خطأ: لم يتم العثور على ملف المفاتيح $KEYS_FILE!"
    exit 1
fi

# قراءة المفاتيح في مصفوفة
mapfile -t keys < "$KEYS_FILE"

echo "إجمالي عدد المفاتيح: ${#keys[@]}"

for key in "${keys[@]}"; do
    NODE_DIR="/root/docker-compose-files/node-$i"
    mkdir -p "$NODE_DIR"
    cd "$NODE_DIR" || exit

    # تحميل السكريبت
    base_script="ocean-node-quickstart.sh"
    curl -s https://raw.githubusercontent.com/oceanprotocol/ocean-node/main/scripts/ocean-node-quickstart.sh -o "$base_script"
    chmod +x "$base_script"

    # حساب المنافذ الديناميكية
    HTTP_API_PORT=$last_used_port
    P2P_IPV4_TCP_PORT=$((last_used_port + 1))
    P2P_IPV4_WS_PORT=$((P2P_IPV4_TCP_PORT + 1))
    P2P_IPV6_TCP_PORT=$((P2P_IPV4_WS_PORT + 1))
    P2P_IPV6_WS_PORT=$((P2P_IPV6_TCP_PORT + 1))

    # تشغيل السكريبت مع القيم المطلوبة
    echo -e "y\n$key\n$ADMIN_ADDRESS\n$HTTP_API_PORT\n$P2P_IPV4_TCP_PORT\n$P2P_IPV4_WS_PORT\n$P2P_IPV6_TCP_PORT\n$P2P_IPV6_WS_PORT\n$BASE_IP\n" | ./$base_script

    # التحقق من نجاح الإنشاء
    if [[ ! -f "docker-compose.yml" ]]; then
        echo "تحذير: لم يتم العثور على docker-compose.yml في $NODE_DIR"
        continue
    fi

    # تعديل أسماء الكونتينرات والمنافذ في docker-compose.yml
    sed -i "s/container_name: ocean-node/container_name: ocean-node-$i/" docker-compose.yml
    sed -i "s/container_name: typesense/container_name: typesense-$i/" docker-compose.yml
    sed -i "s/pull_policy: always/pull_policy: never/" docker-compose.yml
    sed -i '/restart: on-failure/a \ \ \ \ init: true' docker-compose.yml
    sed -i "s/8108:8108/$((10000 + j)):8108/" docker-compose.yml

    # تعديل البورتات بشكل تسلسلي
    sed -i "s/8000:8000/$HTTP_API_PORT:$HTTP_API_PORT/" docker-compose.yml
    sed -i "s/9000:9000/$P2P_IPV4_TCP_PORT:$P2P_IPV4_TCP_PORT/" docker-compose.yml
    sed -i "s/9001:9001/${P2P_IPV4_WS_PORT}:${P2P_IPV4_WS_PORT}/" docker-compose.yml
    sed -i "s/9002:9002/${P2P_IPV6_TCP_PORT}:${P2P_IPV6_TCP_PORT}/" docker-compose.yml
    sed -i "s/9003:9003/${P2P_IPV6_WS_PORT}:${P2P_IPV6_WS_PORT}/" docker-compose.yml

    # تحديث البورتات للاستخدام في العقدة التالية
    last_used_port=$((last_used_port + 5))
    ((i++))
    ((j+=5))

    echo "تم إنشاء وتشغيل العقدة $i في $NODE_DIR"
done

echo "تم انشاء ملفات النودات!"

# --- الخطوة 4: تشغيل جميع الحاويات ---
BASE_DIR="/root/docker-compose-files"

echo "جاري تشغيل جميع الحاويات ..."

for node_dir in $BASE_DIR/node-*; do
    if [[ -f "$node_dir/docker-compose.yml" ]]; then
        echo "تشغيل الحاويات في $node_dir"
        cd "$node_dir" || exit
        sudo docker compose up -d
    else
        echo "لم يتم العثور على docker-compose.yml في $node_dir"
    fi
done

echo "تم تشغيل جميع الحاويات بنجاح!"

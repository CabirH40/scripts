#!/bin/bash

echo "مرحبًا بك في أداة إدارة العقد باستخدام Docker!"

echo "اختر أحد الخيارات التالية:"
echo "1) تثبيت Docker والمتطلبات الخاصة به"
echo "2) إنشاء المفاتيح وملفات النودات"
echo "3) تشغيل عدد معين من العقد (من 0 إلى 100 أو أكثر)"
echo "4) تشغيل جميع الحاويات الموجودة"
echo "5) خروج"

read -p "أدخل رقم الخيار: " choice

case $choice in
    1)
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
        sudo systemctl restart docker

        echo "تنزيل صور Docker ..."
        sudo docker pull typesense/typesense:26.0
        sudo docker pull oceanprotocol/ocean-node:latest
        echo "تم التثبيت بنجاح!"
        ;;
    
    2)
        read -p "كم نود تريد أن تستخدم؟ " key_count

        if ! [[ "$key_count" =~ ^[0-9]+$ ]] || [ "$key_count" -le 0 ]; then
            echo "خطأ: يرجى إدخال رقم صحيح أكبر من الصفر."
            exit 1
        fi

        output_file="prv.txt"
        > "$output_file"
        echo "جاري إنشاء $key_count مفتاحًا ..."

        for ((i=1; i<=key_count; i++)); do
            prv_key="0x$(openssl rand -hex 32)"
            echo "$prv_key" >> "$output_file"
        done

        echo "تم إنشاء $key_count مفتاحًا وحفظها في $output_file بنجاح."

        KEYS_FILE="prv.txt"
        BASE_IP=$(curl -s ifconfig.me)
        BASE_PORT=10000
        TYPESENSE_PORT=9000
        ADMIN_ADDRESS="0x0CB4d01ef8534E132f1f7fa86385B9D30733dab4"

        i=0
        j=8000
        last_used_port=1025

        if [[ ! -f "$KEYS_FILE" ]]; then
            echo "خطأ: لم يتم العثور على ملف المفاتيح $KEYS_FILE!"
            exit 1
        fi

        mapfile -t keys < "$KEYS_FILE"

        echo "إجمالي عدد المفاتيح: ${#keys[@]}"

        for key in "${keys[@]}"; do
            NODE_DIR="/root/docker-compose-files/node-$i"
            mkdir -p "$NODE_DIR"
            cd "$NODE_DIR" || exit

            base_script="ocean-node-quickstart.sh"
            curl -s https://raw.githubusercontent.com/oceanprotocol/ocean-node/main/scripts/ocean-node-quickstart.sh -o "$base_script"
            chmod +x "$base_script"

            HTTP_API_PORT=$last_used_port
            P2P_IPV4_TCP_PORT=$((last_used_port + 1))
            P2P_IPV4_WS_PORT=$((P2P_IPV4_TCP_PORT + 1))
            P2P_IPV6_TCP_PORT=$((P2P_IPV4_WS_PORT + 1))
            P2P_IPV6_WS_PORT=$((P2P_IPV6_TCP_PORT + 1))

            echo -e "y\n$key\n$ADMIN_ADDRESS\n$HTTP_API_PORT\n$P2P_IPV4_TCP_PORT\n$P2P_IPV4_WS_PORT\n$P2P_IPV6_TCP_PORT\n$P2P_IPV6_WS_PORT\n$BASE_IP\n" | ./$base_script

            if [[ ! -f "docker-compose.yml" ]]; then
                echo "تحذير: لم يتم العثور على docker-compose.yml في $NODE_DIR"
                continue
            fi

            sed -i "s/container_name: ocean-node/container_name: ocean-node-$i/" docker-compose.yml
            sed -i "s/container_name: typesense/container_name: typesense-$i/" docker-compose.yml
            sed -i "s/pull_policy: always/pull_policy: never/" docker-compose.yml
            sed -i '/restart: on-failure/a \ \ \ \ init: true' docker-compose.yml
            sed -i "s/8108:8108/$((10000 + j)):8108/" docker-compose.yml

            sed -i "s/8000:8000/$HTTP_API_PORT:$HTTP_API_PORT/" docker-compose.yml
            sed -i "s/9000:9000/$P2P_IPV4_TCP_PORT:$P2P_IPV4_TCP_PORT/" docker-compose.yml
            sed -i "s/9001:9001/${P2P_IPV4_WS_PORT}:${P2P_IPV4_WS_PORT}/" docker-compose.yml
            sed -i "s/9002:9002/${P2P_IPV6_TCP_PORT}:${P2P_IPV6_TCP_PORT}/" docker-compose.yml
            sed -i "s/9003:9003/${P2P_IPV6_WS_PORT}:${P2P_IPV6_WS_PORT}/" docker-compose.yml

            last_used_port=$((last_used_port + 5))
            ((i++))
            ((j+=5))

            echo "تم إنشاء وتشغيل العقدة $i في $NODE_DIR"
        done

        echo "تم انشاء ملفات النودات!"
        ;;
    
    3)
        read -p "كم عدد العقد التي تريد تشغيلها؟ " node_count
        if ! [[ "$node_count" =~ ^[0-9]+$ ]] || [ "$node_count" -lt 0 ]; then
            echo "خطأ: يرجى إدخال رقم صحيح أكبر من أو يساوي 0."
            exit 1
        fi
        
        BASE_DIR="/root/docker-compose-files"
        for ((i=0; i<=node_count; i++)); do
            NODE_DIR="$BASE_DIR/node-$i"
            if [[ -f "$NODE_DIR/docker-compose.yml" ]]; then
                echo "تشغيل العقدة $i ..."
                cd "$NODE_DIR" || exit
                sudo docker compose up -d
            else
                echo "تحذير: لم يتم العثور على docker-compose.yml في $NODE_DIR"
            fi
        done
        echo "تم تشغيل العقد المحددة بنجاح!"
        ;;
    4)
        echo "جاري تشغيل جميع الحاويات ..."
        BASE_DIR="/root/docker-compose-files"
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
        ;;
    5)
        echo "خروج ..."
        exit 0
        ;;
    *)
        echo "خيار غير صحيح، يرجى المحاولة مرة أخرى."
        ;;
esac

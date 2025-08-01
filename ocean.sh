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
  ],
  "dns": ["8.8.8.8", "8.8.4.4"]
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
# Telegram bot details
telegram_token='6771313174:AAGSrlGl7LnJg1ewGlaS6QO5fpL5OVXJNWg'
telegram_group='-1002175706144'
telegram_user_tag="@CabirH2000 @testnetsever"
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

# Define all node configurations: path_to_workspace:rpc_port
declare -A nodes=(
  ["/root/.humanode/workspaces/default/workspace.json"]="9944"
  ["/home/node1/.humanode/workspaces/default/workspace.json"]="9945"
  ["/home/node2/.humanode/workspaces/default/workspace.json"]="9946"
  ["/home/node3/.humanode/workspaces/default/workspace.json"]="9947"
  ["/home/node4/.humanode/workspaces/default/workspace.json"]="9948"
  ["/home/node5/.humanode/workspaces/default/workspace.json"]="9949"
  ["/home/node6/.humanode/workspaces/default/workspace.json"]="9950"
  ["/home/node7/.humanode/workspaces/default/workspace.json"]="9951"
  ["/home/node8/.humanode/workspaces/default/workspace.json"]="9952"
  ["/home/node9/.humanode/workspaces/default/workspace.json"]="9953"
)

# Loop through all nodes
for workspace_file in "${!nodes[@]}"; do
    rpc_port="${nodes[$workspace_file]}"
    process_name="humanode-peer"

    # Skip if workspace file doesn't exist
    if [ ! -f "$workspace_file" ]; then
        echo "⚠️ File $workspace_file not found, skipping..."
        continue
    fi

    nodename=$(jq -r '.nodename' "$workspace_file")
    server_ip=$(curl -s https://api.ipify.org)

    # Check if humanode-peer is running
    if ! pgrep -x "$process_name" > /dev/null; then
        echo "ℹ️ $nodename ($workspace_file): process not running, skipping..."
        continue
    fi

    # Get auth URL from local file
    if [ "$workspace_file" == "/root/.humanode/workspaces/default/workspace.json" ]; then
        auth_url=$(cat /root/script/link/link.txt 2>/dev/null)
    else
        node_number=$(echo "$workspace_file" | grep -oP 'node\K[0-9]+')
        auth_url=$(cat "/root/script/node${node_number}/link/link.txt" 2>/dev/null)
    fi

    # If no auth_url found, skip this node
    if [ -z "$auth_url" ]; then
        echo "❌ No auth_url found for $nodename, skipping..."
        continue
    fi

    # Get bioauth status
    status=$(curl -s "http://127.0.0.1:${rpc_port}" -X POST -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result')

    if [ "$(echo "$status" | tr '[:upper:]' '[:lower:]')" == '"inactive"' ]; then
        message="🚨 ${nodename} humanode (${server_ip}) is not active, please proceed to do re-authentication ${telegram_user_tag} ${auth_url}"
    else
        current_timestamp=$(date +%s)
        expires_at=$(curl -s "http://127.0.0.1:${rpc_port}" -X POST -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')
        difference=$(( (expires_at / 1000 - current_timestamp) / 60 ))

        if (( difference > 25 && difference < 31 )); then
            message="🟡 ${nodename} humanode (${server_ip}) will be deactivated in 30 minutes, please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
        elif (( difference > 0 && difference < 6 )); then
            message="🔴 ${nodename} humanode (${server_ip}) will be deactivated in 5 minutes, please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
        else
            message="NULL"
        fi
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
    if [ "$message" != "NULL" ]; then
        curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
    fi
done

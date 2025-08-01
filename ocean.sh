#!/bin/bash

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

    if [ "$message" != "NULL" ]; then
        curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
    fi
done

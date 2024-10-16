#!/bin/bash

# Telegram bot details
telegram_token='6771313174:AAGSrlGl7LnJg1ewGlaS6QO5fpL5OVXJNWg'
telegram_group='-1002175706144'
telegram_user_tag="@CabirH2000 @testnetsever"
process_name="humanode-peer"
workspace_file="/root/.humanode/workspaces/default/workspace.json" # تأكد من مسار ملف JSON
nodename=$(jq -r '.nodename' $workspace_file)

# Execute command to fetch authentication URL
auth_url=$(/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json)

# Script starts here
server_ip=$(curl -s https://api.ipify.org)
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

# Check the status of the process
if ! pgrep -x "$process_name" > /dev/null; then
  message="🚨Server ${nodename} (${server_ip}) process ${process_name} has been stopped ${telegram_user_tag}"
else
  status=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result')

  if [ "$(echo "$status" | tr '[:upper:]' '[:lower:]')" == "$(echo '"inactive"' | tr '[:upper:]' '[:lower:]')" ]; then
    message="🚨${nodename} humanode (${server_ip}) is not active, please proceed to do re-authentication ${telegram_user_tag} ${auth_url}"
  else
    current_timestamp=$(date +%s)
    expires_at=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')
    difference=$(( (expires_at / 1000 - current_timestamp) / 60 ))

    if (( difference > 25 && difference < 31 )); then
      message=" ${nodename} humanode (${server_ip}) will be deactivated in 30 minutes, please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
    elif (( difference > 0 && difference < 6 )); then
      message="🔴${nodename} humanode (${server_ip}) will be deactivated in 5 minutes, please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
    
    # New condition for 24 hours notification
    elif (( difference > 1440 && difference < 1446 )); then
      auth_time=$(date -d "@$(( (expires_at / 1000) ))" '+%Y-%m-%d %H:%M:%S')
      message="⏳${nodename} humanode (${server_ip}) will require re-authentication in 24 hours at ${auth_time}. Please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
    else
      message="NULL"
    fi
  fi
fi

# Send message if there is any alert
if [ "$message" != "NULL" ]; then
  curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
fi

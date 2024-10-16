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

# Get the current timestamp
current_timestamp=$(date +%s)

# Get expiration time
expires_at=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')

# Calculate the time when re-authentication is needed
auth_time=$(date -d "@$(( (expires_at / 1000) ))" '+%Y-%m-%d %H:%M:%S')

# Convert auth_time to Turkey time
turkey_time=$(TZ="Europe/Istanbul" date -d "$auth_time" '+%Y-%m-%d %H:%M:%S')

# Get the day of the week
day_of_week=$(TZ="Europe/Istanbul" date -d "$auth_time" '+%A')

# Create message with time and day
message="🕒 ${nodename} humanode requires re-authentication at ${turkey_time} (${day_of_week}). ${telegram_user_tag} ${auth_url}"

# Send message
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"
curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}

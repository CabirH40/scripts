#!/bin/bash

# Telegram bot details
telegram_token='6771313174:AAGSrlGl7LnJg1ewGlaS6QO5fpL5OVXJNWg'
telegram_group='-1002175706144'
telegram_user_tag="@CabirH2000 @testnetsever"
workspace_file="/root/.humanode/workspaces/default/workspace.json" 
nodename=$(jq -r '.nodename' $workspace_file)

# Execute command to fetch authentication URL
auth_url=$(/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json)

# Prepare the three URLs
url1="${auth_url}"
url2="${auth_url}/authenticate"
url3="${auth_url}/setup-node/enroll"

# Get server IP
server_ip=$(curl -s https://api.ipify.org)

# Prepare the message with three URLs
message="🚀 ${nodename} humanode (${server_ip}) authentication URLs:
1. ${url1}
2. ${url2}
3. ${url3}
${telegram_user_tag}"

# Telegram API endpoint
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

# Send the message
curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}

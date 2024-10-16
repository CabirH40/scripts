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

# Get the current timestamp
current_timestamp=$(date +%s)

# Check the status of the process and expiration time
expires_at=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')
difference=$(( (expires_at / 1000 - current_timestamp) / 60 ))

# Initialize the message
message="NULL"

# Check for re-authentication conditions
if (( difference > 1440 && difference < 1446 )); then
    auth_time=$(date -d "@$(( (expires_at / 1000) ))" '+%Y-%m-%d %H:%M:%S')
    
    # Convert auth_time to Turkey time
    turkey_time=$(TZ="Europe/Istanbul" date -d "$auth_time" '+%Y-%m-%d %H:%M:%S')
    
    # Get the day of the week
    day_of_week=$(TZ="Europe/Istanbul" date -d "$auth_time" '+%A')

    message="⏳ ${nodename} humanode (${server_ip}) will require re-authentication in 24 hours at ${turkey_time} (${day_of_week}). Please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
elif ! pgrep -x "humanode-peer" > /dev/null; then
    message="🚨 Server ${nodename} (${server_ip}) process humanode-peer has been stopped ${telegram_user_tag}"
else
    status=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result')

    if [ "$(echo "$status" | tr '[:upper:]' '[:lower:]')" == "$(echo '"inactive"' | tr '[:upper:]' '[:lower:]')" ]; then
        message="🚨 ${nodename} humanode (${server_ip}) is not active, please proceed to do re-authentication ${telegram_user_tag} ${auth_url}"
    else
        if (( difference > 25 && difference < 31 )); then
            message="${nodename} humanode (${server_ip}) will be deactivated in 30 minutes, please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
        elif (( difference > 0 && difference < 6 )); then
            message="🔴 ${nodename} humanode (${server_ip}) will be deactivated in 5 minutes, please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
        fi
    fi
fi

# Prepare the message with three URLs if no alerts
if [ "$message" == "NULL" ]; then
    message="🚀 ${nodename} humanode (${server_ip}) authentication URLs:
1. ${url1}
2. ${url2}
3. ${url3}
${telegram_user_tag}"
fi

# Telegram API endpoint
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

# Send the message if it's not NULL
if [ "$message" != "NULL" ]; then
    curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
fi

#!/bin/bash
telegram_token='7012892705:AAE415279VXhOZHNxo-4tlqtHSa1gVpXS5I'
telegram_group='-4270399214'
telegram_user_tag="@CabirH2000 @testnetsever"
process_name="humanode-peer"
# Stop editing

# Script starts here
server_ip=$(curl -s https://api.ipify.org)
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

# Check the status of the process
if ! pgrep -x "$process_name" > /dev/null; then
  message="🚨Server sehel (${server_ip}) process ${process_name} has been stopped ${telegram_user_tag}"
else
  status=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result')

  if [ "$(echo "$status" | tr '[:upper:]' '[:lower:]')" == "$(echo '"inactive"' | tr '[:upper:]' '[:lower:]')" ]; then
    message="🚨sehel Humanode (${server_ip}) is not active, please proceed to do re-authentication ${telegram_user_tag}"
  else
    current_timestamp=$(date +%s)
    expires_at=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')
    difference=$(( (expires_at / 1000 - current_timestamp) / 60 ))

    if (( difference > 25 && difference < 31 )); then
      message="🟡sehel Humanode (${server_ip}) will be deactivated in 30 minutes, please prepare for re-authentication ${telegram_user_tag}"
    elif (( difference > 0 && difference < 6 )); then
      message="🔴sehel Humanode (${server_ip}) will be deactivated in 5 minutes, please prepare for re-authentication ${telegram_user_tag}"
    else
      message="NULL"
    fi
  fi
fi

# Send message if there is any alert
if [ "$message" != "NULL" ]; then
  curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
fi


#!/bin/bash

telegram_token='6771313174:AAGSrlGl7LnJg1ewGlaS6QO5fpL5OVXJNWg'
telegram_group='-1002175706144'
telegram_user_tag="@CabirH2000 @testnetsever"
workspace_file="/root/.humanode/workspaces/default/workspace.json"
nodename=$(jq -r '.nodename' $workspace_file)
process_name="humanode-peer"
server_ip=$(curl -s https://api.ipify.org)
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

was_down=false

while true; do
  if ! pgrep -x "$process_name" > /dev/null; then
    if [ "$was_down" = false ]; then
      message="🚨 Server ${nodename} (${server_ip}) process ${process_name} has been stopped ${telegram_user_tag}"
      curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
      was_down=true
    fi
  else
    if [ "$was_down" = true ]; then
      message="✅ Server ${nodename} (${server_ip}) process ${process_name} is back online ${telegram_user_tag}"
      curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
      was_down=false
    fi
  fi
  sleep 60
done

#!/bin/bash

telegram_token='7487057135:AAGMsz0I2lFlwM_huwnw22LTg2gVvsdkvAs'
telegram_group='-4766093448'
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

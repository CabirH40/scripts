
telegram_token='6771313174:AAGSrlGl7LnJg1ewGlaS6QO5fpL5OVXJNWg'
telegram_group='-1002175706144'
telegram_user_tag="@CabirH2000 @testnetsever"
process_name="humanode-peer"
workspace_file="/root/.humanode/workspaces/default/workspace.json" 
nodename=$(jq -r '.nodename' $workspace_file)


auth_url=$(/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json)


server_ip=$(curl -s https://api.ipify.org)
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"


current_time_istanbul=$(curl -s "http://worldtimeapi.org/api/timezone/Europe/Istanbul" | jq '.unixtime')


expires_at=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')


expires_at_seconds=$((expires_at / 1000))


difference=$(( expires_at_seconds - current_time_istanbul ))
remaining_days=$(( difference / 86400 ))
remaining_hours=$(( (difference % 86400) / 3600 ))
remaining_minutes=$(( (difference % 3600) / 60 ))


target_time=$(TZ="Europe/Istanbul" date -d "@${expires_at_seconds}" "+%A %H:%M")

initial_message="${nodename} humanode (${server_ip}) will be deactivated at ${target_time}, please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${initial_message}" ${telegram_bot}

if ! pgrep -x "$process_name" > /dev/null; then
  message="🚨Server ${nodename} (${server_ip}) process ${process_name} has been stopped ${telegram_user_tag}"
else
  status=$(curl -s http://127.0.0.1:9933 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result')

  if [ "$(echo "$status" | tr '[:upper:]' '[:lower:]')" == "$(echo '"inactive"' | tr '[:upper:]' '[:lower:]')" ]; then
    message="🚨${nodename} humanode (${server_ip}) is not active, please proceed to do re-authentication ${telegram_user_tag} ${auth_url}"
  else
    current_timestamp=$(date +%s)

  
    difference=$(( expires_at_seconds - current_timestamp ))

  
    remaining_days=$(( difference / 86400 ))
    remaining_hours=$(( (difference % 86400) / 3600 ))
    remaining_minutes=$(( (difference % 3600) / 60 ))

   
    if (( difference <= 1800 )); then
      target_time=$(TZ="Europe/Istanbul" date -d "@$expires_at_seconds" "+%A %H:%M")
      message="🔴${nodename} humanode (${server_ip}) will be deactivated at ${target_time} (in ${remaining_days} days, ${remaining_hours} hours, ${remaining_minutes} minutes), please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
    else
      target_time=$(TZ="Europe/Istanbul" date -d "@$expires_at_seconds" "+%A %H:%M")
      message="${nodename} humanode (${server_ip}) will be deactivated at ${target_time} (in ${remaining_days} days, ${remaining_hours} hours, ${remaining_minutes} minutes), please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
    fi
  fi
fi


if [ "$message" != "NULL" ]; then
  curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
fi

#!/bin/bash

telegram_token='6771313174:AAGSrlGl7LnJg1ewGlaS6QO5fpL5OVXJNWg'
telegram_group='-1002175706144'
telegram_user_tag="@CabirH2000 @testnetsever"
process_name="humanode-peer"
workspace_file="/root/.humanode/workspaces/default/workspace.json" 
nodename=$(jq -r '.nodename' $workspace_file)

auth_url="$(curl -s https://api.ipify.org):2025"

server_ip=$(curl -s https://api.ipify.org)
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

# التوقيت الحالي من النظام
current_time=$(date +%s)

# جلب وقت انتهاء العملية من JSON
expires_at=$(curl -s http://127.0.0.1:9944 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result.Active.expires_at')

# تحويل expires_at إلى ثوانٍ
expires_at_seconds=$((expires_at / 1000))

# حساب الفرق الزمني
difference=$(( expires_at_seconds - current_time ))

# حساب الأيام، الساعات، والدقائق المتبقية
remaining_days=$(( difference / 86400 ))
remaining_hours=$(( (difference % 86400) / 3600 ))
remaining_minutes=$(( (difference % 3600) / 60 ))

# صيغة الوقت المستهدف
target_time=$(TZ="Europe/Istanbul" date -d "@${expires_at_seconds}" "+%A %H:%M")

if ! pgrep -x "$process_name" > /dev/null; then
  message="🚨Server ${nodename} (${server_ip}) process ${process_name} has been stopped ${telegram_user_tag}"
else
  status=$(curl -s http://127.0.0.1:9944 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}' | jq '.result')

  if [ "$(echo "$status" | tr '[:upper:]' '[:lower:]')" == "$(echo '"inactive"' | tr '[:upper:]' '[:lower:]')" ]; then
    message="🚨${nodename} humanode (${server_ip}) is not active, please proceed to do re-authentication ${telegram_user_tag} ${auth_url}"
  else
    if (( difference <= 86400 )); then # تحقق إذا كان الفرق أقل أو يساوي 24 ساعة
      message="🔴${nodename} humanode (${server_ip}) will be deactivated at ${target_time} (in ${remaining_days} days, ${remaining_hours} hours, ${remaining_minutes} minutes), please prepare for re-authentication ${telegram_user_tag} ${auth_url}"
    else
      message="NULL" # إذا لم يتحقق الشرط، لا يتم إرسال أي رسالة
    fi
  fi
fi

if [ "$message" != "NULL" ]; then
  curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=${telegram_group} -F text="${message}" ${telegram_bot}
fi

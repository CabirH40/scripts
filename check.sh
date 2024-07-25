#!/bin/bash

# Telegram bot details
telegram_token='6771313174:AAGSrlGl7LnJg1ewGlaS6QO5fpL5OVXJNWg'
telegram_group='-1002175706144'
telegram_user_tag="@CabirH2000 @testnetsever"

# Server details
servers=(
  138.68.161.220
  159.65.16.152
  159.65.16.196
  206.189.118.99
  209.97.179.163
  91.151.93.180
  91.151.93.148
  206.189.21.48
  91.151.93.167
  178.128.170.4
  139.59.188.72
  91.151.93.126
  91.151.93.178
  91.151.93.179
  91.151.93.140
  91.151.93.172
  91.151.93.59
  91.151.93.192
  91.151.93.194
  91.151.93.204
  91.151.90.243
  91.151.90.113
  91.151.93.38
  91.151.93.122
  91.151.93.68
  91.151.93.56
  157.230.220.212
  198.199.65.165
  159.223.134.170
  91.151.93.223
  91.151.93.82
  91.151.93.6
  91.151.90.164
  91.151.93.91
  159.89.9.229
  159.65.121.44
  157.230.31.129
  68.183.78.30
  139.59.153.45
  164.90.225.131
  68.183.220.107
  64.226.77.130
  91.151.90.211
  45.90.121.210
  157.245.5.147
  91.151.93.212
  91.151.90.135
  67.205.136.136
  68.183.214.160
  91.151.90.124
  91.151.90.39
  213.199.54.159
  213.199.54.148
  213.199.54.146
  213.199.54.160
  68.183.210.69
  91.151.93.22
  91.151.90.87
  91.151.93.97
  91.151.93.104
  91.151.90.254
  91.151.90.225
  91.151.90.41
  91.151.90.197
  91.151.90.101
  91.151.90.151
  91.151.90.94
)
ssh_key_path="4Y8z1eblEJ" # مسار مفتاح SSH الخاص بك
ssh_user="root"

# Telegram API URL
telegram_bot="https://api.telegram.org/bot${telegram_token}/sendMessage"

# Function to check server status
check_server() {
  local server_ip=$1
  if ssh -i "${ssh_key_path}" -q "${ssh_user}@${server_ip}" "exit" &>/dev/null; then
    # If SSH connection is successful, do nothing
    :
  else
    # If SSH connection fails, create a message with the failed server's IP
    local message="⚠️ فشل الاتصال في هذا السيرفر: ${server_ip} ${telegram_user_tag}"
    # Debugging: Print the message to verify its correctness
    echo "Debug: ${message}"
    # Send the message to Telegram
    curl -s -X POST -d "chat_id=${telegram_group}" -d "text=${message}" ${telegram_bot} >/dev/null
  fi
}

# Loop through each server and check status
for server_ip in "${servers[@]}"; do
  check_server "$server_ip"
done

echo "Script completed."

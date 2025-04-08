#!/usr/bin/env python3

import requests
import time
import subprocess
import json

telegram_token = '7487057135:AAGMsz0I2lFlwM_huwnw22LTg2gVvsdkvAs'
telegram_group = '-4766093448'
telegram_user_tag = '@CabirH2000 @testnetsever'
workspace_file = '/root/.humanode/workspaces/default/workspace.json'
process_name = 'humanode-peer'

with open(workspace_file, 'r') as f:
    nodename = json.load(f).get('nodename', 'unknown-node')

try:
    server_ip = requests.get('https://api.ipify.org').text.strip()
except:
    server_ip = '0.0.0.0'

telegram_api = f"https://api.telegram.org/bot{telegram_token}/sendMessage"

def is_process_running(name):
    try:
        subprocess.check_output(['pgrep', '-x', name])
        return True
    except subprocess.CalledProcessError:
        return False

while True:
    if not is_process_running(process_name):
        message = f"ðŸš¨ Server {nodename} ({server_ip}) process {process_name} has been stopped {telegram_user_tag}"
        try:
            requests.post(telegram_api, data={
                'chat_id': telegram_group,
                'text': message
            })
        except Exception as e:
            print("Telegram error:", e)
    time.sleep(30)


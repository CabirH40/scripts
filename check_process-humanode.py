#!/usr/bin/env python3

import requests
import time
import subprocess
import json
import datetime

# إعدادات تيليجرام
telegram_token = '7487057135:AAGMsz0I2lFlwM_huwnw22LTg2gVvsdkvAs'
telegram_group = '-1002639328852'
telegram_user_tag = '@CabirH2000 @testnetsever'
telegram_api = f"https://api.telegram.org/bot{telegram_token}/sendMessage"

# ملف اللوقات
log_file = '/var/log/check_process-humanode.log'

# اسم العقدة
workspace_file = '/root/.humanode/workspaces/default/workspace.json'
try:
    with open(workspace_file, 'r') as f:
        nodename = json.load(f).get('nodename', 'unknown-node')
except Exception:
    nodename = 'unknown-node'

# الحصول على IP
def get_ip():
    try:
        return requests.get('https://api.ipify.org').text.strip()
    except:
        return "0.0.0.0"

server_ip = get_ip()

# فحص إذا كان البورت في حالة LISTEN
def is_port_listening(port):
    try:
        result = subprocess.run(
            f"ss -tuln | grep ':{port} ' | grep LISTEN",
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        return result.returncode == 0
    except:
        return False

# تسجيل في ملف لوق
def write_log(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(log_file, 'a') as log:
        log.write(f"[{timestamp}] {message}\n")

# لتجنب التكرار
last_status = None
last_sent_time = 0
repeat_interval = 300  # 5 دقائق = 300 ثانية

while True:
    is_9944 = is_port_listening(9944)
    is_30333 = is_port_listening(30333)

    write_log(f"CHECK: 9944={is_9944}, 30333={is_30333}")

    status = "ok"
    message = None

    if not is_9944 and not is_30333:
        status = "peer_stopped"
        message = (
            f"❌ العقدة {nodename} (IP: {server_ip}) متوقفة تمامًا.\n"
            f"30333 و 9944 لا يعملان (LISTEN).\n"
            f"{telegram_user_tag}"
        )
    elif not is_9944 and is_30333:
        status = "tunnel_down"
        message = (
            f"❌ التونل (9944) لا يعمل (LISTEN) على العقدة {nodename} (IP: {server_ip}).\n"
            f"{telegram_user_tag}"
        )
    elif is_9944 and is_30333:
        status = "ok"
        if last_status and last_status != "ok":
            message = (
                f"✅ العقدة {nodename} (IP: {server_ip}) عادت للعمل بشكل طبيعي ✅\n"
                f"البورتات 9944 و 30333 في وضع الاستماع الآن."
            )

    now = time.time()

    should_send = False
    if message:
        if status != last_status:
            should_send = True
        elif status == last_status and status != "ok" and (now - last_sent_time) >= repeat_interval:
            should_send = True

    if should_send:
        write_log(f"SEND: {message}")
        try:
            r = requests.post(telegram_api, data={
                'chat_id': telegram_group,
                'text': message
            })
            if r.status_code == 200:
                write_log("TELEGRAM: ✅ تم الإرسال بنجاح")
                last_status = status
                last_sent_time = now
            else:
                write_log(f"TELEGRAM: ❌ فشل الإرسال - Status: {r.status_code} - Response: {r.text}")
        except Exception as e:
            write_log(f"TELEGRAM ERROR: {e}")

    time.sleep(30)

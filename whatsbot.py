import os
import json
import requests
import time
import paramiko
import schedule
import pytz
import logging
from datetime import datetime
from pathlib import Path

# إعداد السجل
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# المسارات والثوابت
workspace_file = Path("/root/.humanode/workspaces/default/workspace.json")
remote_file_path = "/root/whatsapp-bot/what.txt"

# بيانات السيرفر البعيد
remote_ip = "152.53.84.199"
remote_user = "root"
remote_password = "4Y8z1eblEJ"  # مرئية كما طلبت

# الحالة العامة
alert_30_sent = alert_5_sent = alert_4_sent = alert_sent = False
alert_missed_count = 0
missed_alert_last_time = 0
phone = "905312395611"
last_expires_at = 0
last_status = None
last_alert_time = 0

# الحصول على IP الحالي للسيرفر
server_ip = requests.get("https://ifconfig.me").text

def restart_whatsbot_service():
    try:
        subprocess.run(["sudo", "systemctl", "restart", "whatsbot.service"], check=True)
        print("✅ تم إعادة تشغيل الخدمة بنجاح.")
    except subprocess.CalledProcessError as e:
        print(f"❌ فشل في إعادة التشغيل: {e}")
def get_auth_url():
    while True:
        try:
            result = os.popen(
                "/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json"
            ).read().strip()
            if result:
                logging.info(f"✅ auth_url: {result}")
                return result
        except Exception as e:
            logging.warning(f"فشل جلب auth_url: {e}")
        time.sleep(5)


def get_nodename():
    try:
        with open(workspace_file) as f:
            data = json.load(f)
        return data.get("nodename", "Unknown")
    except Exception as e:
        logging.error(f"خطأ في قراءة nodename: {e}")
        return "Unknown"


def get_status():
    while True:
        try:
            res = requests.post(
                "http://127.0.0.1:9944",
                headers={"Content-Type": "application/json"},
                data=json.dumps({"jsonrpc": "2.0", "method": "bioauth_status", "params": [], "id": 1})
            )
            data = res.json()
            result = data.get("result", {})
            if "Active" in result:
                expires_at = result["Active"].get("expires_at", 0)
                return int(expires_at / 1000), "Active"
            elif "Inactive" in result:
                return 0, "Inactive"
        except:
            logging.warning("فشل في جلب حالة التوثيق. إعادة المحاولة...")
            time.sleep(19)


def reset_alerts():
    global alert_sent, alert_30_sent, alert_5_sent, alert_4_sent, alert_missed_count, missed_alert_last_time
    alert_sent = alert_30_sent = alert_5_sent = alert_4_sent = False
    alert_missed_count = 0
    missed_alert_last_time = 0
    logging.info("✅ تم إعادة تعيين جميع التنبيهات")


schedule.every().day.at("02:00").do(reset_alerts)


def send_message_to_server(message, phone):
    try:
        full_message = f"{phone} {message}"

        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(remote_ip, username=remote_user, password=remote_password)
        sftp = ssh.open_sftp()

        try:
            with sftp.open(remote_file_path, 'r') as f:
                old_content = f.read().decode()
        except:
            old_content = ""

        with sftp.open(remote_file_path, 'w') as f:
            f.write(full_message + "\n" + old_content)

        sftp.close()
        ssh.close()
        logging.info("📨 تم إرسال الرسالة بنجاح")
    except Exception as e:
        logging.error(f"خطأ في إرسال الرسالة عبر SFTP: {e}")


def fetch_phone_number(nodename):
    try:
        res = requests.get(f"http://152.53.84.199/read_csv.php?node={nodename}")
        data = res.json()
        return data.get("phone")
    except:
        return None


def update_phone_if_needed():
    global phone
    new_phone = fetch_phone_number(nodename)
    if new_phone:
        phone = new_phone
        logging.info(f"📞 تم تحديث رقم الهاتف: {phone}")


def format_message(minutes, expires_at):
    tz = pytz.timezone("Europe/Istanbul")
    time_str = datetime.fromtimestamp(expires_at).astimezone(tz).strftime("%I:%M %p")



    return f"{nodename}  -يجب التصوير في الوقت المكتوب تماما: {time_str} - {auth_url}"


def handle_status_and_alerts():
    global last_expires_at, alert_5_sent, alert_30_sent, alert_4_sent, alert_sent, last_alert_time, last_status, alert_missed_count, missed_alert_last_time

    current_time = int(time.time())
    expires_at, status = get_status()
    diff = expires_at - current_time
    msg = None

    if expires_at != last_expires_at:
        reset_alerts()
        last_expires_at = expires_at

    if time.time() - last_alert_time > 20:
        if 0 <= diff < 310 and not alert_5_sent:
            msg = format_message(5, expires_at)
            alert_5_sent = True
            get_auth_url()
            update_phone_if_needed()
            last_alert_time = time.time()

        if 310 <= diff < 1810 and not alert_30_sent:
            msg = format_message(30, expires_at)
            alert_30_sent = True
            update_phone_if_needed()
            last_alert_time = time.time()

        if 1810 <= diff < 3200 and not alert_4_sent:
            get_auth_url()
            msg = format_message(240, expires_at)
            alert_4_sent = True
            restart_whatsbot_service()
            update_phone_if_needed()
            last_alert_time = time.time()

    if status == "Inactive" and not alert_sent and alert_missed_count < 3:
        if missed_alert_last_time == 0 or current_time - missed_alert_last_time >= 600:
            send_message_to_server(f"⏰ ({nodename}) - {auth_url} - يجب التصوير فورا", phone)
            alert_missed_count += 1
            update_phone_if_needed()
            missed_alert_last_time = current_time

    if last_status == "Inactive" and status == "Active":
        update_phone_if_needed()
        send_message_to_server(f"🎉 {nodename} ✅ تم التوثيق بنجاح! نراك بعد أسبوع إن شاء الله.", phone)
        alert_sent = True

    last_status = status

    if msg:
        send_message_to_server(msg, phone)
    time.sleep(10)

def main_loop():
    while True:
        get_nodename():
        update_phone_if_needed()
        handle_status_and_alerts()
        schedule.run_pending()
        time.sleep(20)


if __name__ == "__main__":
    nodename = get_nodename()
    auth_url = get_auth_url()
    time_started = time.time()
    main_loop()

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
import subprocess
import threading
# إعداد السجل
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Telegram إعداد
BOT_TOKEN = "7839318486:AAF8Jk6rqsgGlLT4KvI1EsXVs24qilPlWiQ"
CHAT_ID = "-1002517987939"

# المسارات والثوابت
workspace_file = Path("/root/.humanode/workspaces/default/workspace.json")
remote_file_path = "/root/whatsapp-bot/what.txt"
remote_ip = "5.180.81.233"
remote_user = "root"
remote_password = "Gorahal"

# متغيرات حالة
alert_30_sent = alert_5_sent = alert_4_sent = alert_sent = False
alert_missed_count = 0
missed_alert_last_time = 0
last_expires_at = 0
last_status = None
last_alert_time = 0
phone = "905312395611"
auth_url = "Unavailable"
monitoring_auth_url = False

# جلب IPv4 الحالي حصراً
try:
    server_ip = requests.get("https://ipv4.icanhazip.com", timeout=5).text.strip()
except Exception as e:
    server_ip = "unknown"
    logging.error(f"❌ فشل في الحصول على IPv4: {e}")

def send_telegram_error(message):
    try:
        full_message = f"📡 IP: {server_ip}\n{message}"
        print(f"📡 Sending to Telegram: {full_message}")
        url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
        payload = {
            "chat_id": CHAT_ID,
            "text": full_message
        }
        res = requests.post(url, json=payload, timeout=5)
        print("✅ Telegram Response:", res.status_code, res.text)
    except Exception as e:
        logging.error(f"فشل في إرسال الخطأ إلى Telegram: {e}")

def get_live_auth_url():
    try:
        # 📄 قراءة الرابط من الملف مباشرة
        with open("/root/link/link.txt", "r") as f:
            url = f.read().strip()
        if url.startswith("http"):
            logging.info(f"✅ تم جلب رابط التوثيق من الملف: {url}")
            return url
        else:
            raise Exception(f"الرابط غير صالح في الملف: {url}")
    except Exception as e:
        error_message = f"⚠️ فشل في قراءة رابط التوثيق من الملف:\n{str(e)}"
        send_telegram_error(error_message)
        return "Unavailable"
        
def monitor_auth_url_updates():
    global monitoring_auth_url, auth_url
    try:
        monitoring_auth_url = True
        previous_url = get_live_auth_url()
        auth_url = previous_url
        logging.info("🔍 بدأت مراقبة رابط التوثيق كل 60 ثانية (رابط مبكر).")
        while monitoring_auth_url:
            time.sleep(10)
            current_url = get_live_auth_url()
            if current_url != previous_url and current_url != "Unavailable":
                previous_url = current_url
                auth_url = current_url
                logging.info("🔄 تم تحديث رابط التوثيق.")
                send_telegram_error(f"🔄 تم تحديث رابط التوثيق:\n{current_url}")
                #send_message_to_server(f"⏰ ({get_nodename()}) - {current_url} - تم تحديث رابط التوثيق", phone)
    except Exception as e:
        send_telegram_error(f"🧨 خطأ أثناء مراقبة الرابط المبكر:\n{e}")

def get_nodename():
    try:
        with open(workspace_file) as f:
            data = json.load(f)
        return data.get("nodename", "Unknown")
    except Exception as e:
        logging.error(f"💥 خطأ في قراءة nodename: {e}")
        send_telegram_error(f"💥 خطأ في قراءة nodename: {e}")
        return "Unknown"

def get_status():
    try:
        res = requests.post("http://127.0.0.1:9944", headers={"Content-Type": "application/json"},
                            data=json.dumps({"jsonrpc": "2.0", "method": "bioauth_status", "params": [], "id": 1}))
        data = res.json()
        result = data.get("result", {})
        if "Active" in result:
            return int(result["Active"].get("expires_at", 0) / 1000), "Active"
        elif "Inactive" in result:
            return 0, "Inactive"
        else:
             send_telegram_error(f"🚫 فشل في جلب حالة التوثيق: {e}")
             return 0, "Unknown"
    except Exception as e:
        logging.warning(f"🚫 فشل في جلب حالة التوثيق: {e}")
        send_telegram_error(f"🚫 فشل في جلب حالة التوثيق: {e}")
    return 0, "Error"

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
        logging.error(f"💥 خطأ في إرسال الرسالة عبر SFTP: {e}")
        send_telegram_error(f"💥 خطأ في إرسال الرسالة عبر SFTP: {e}")

def fetch_phone_number(nodename):
    try:
        res = requests.get(f"http://5.180.81.233/read_csv.php?node={nodename}")
        data = res.json()
        return data.get("phone")
    except Exception as e:
        logging.warning(f"❌ فشل في جلب رقم الهاتف: {e}")
        send_telegram_error(f"❌ فشل في جلب رقم الهاتف: {e}")
        return None

def update_phone_if_needed():
    global phone
    new_phone = fetch_phone_number(get_nodename())
    if new_phone and new_phone != phone:
        phone = new_phone
        logging.info(f"📞 تم تحديث رقم الهاتف: {phone}")

def format_message(minutes, expires_at):
    tz = pytz.timezone("Europe/Istanbul")
    time_str = datetime.fromtimestamp(expires_at).astimezone(tz).strftime("%I:%M %p")
    return f"{nodename}  - 🤭 يجب التصوير في الوقت المكتوب تماما: ({time_str}) - {auth_url}"

def handle_status_and_alerts2():
    global monitoring_auth_url
    expires_at, status = get_status()
    current_time = int(time.time())
    diff = expires_at - current_time
    if diff < 7000 and not monitoring_auth_url:
        logging.info("🤭 بقي أكثر من 10 دقائق، بدء مراقبة الرابط المبكر...")
        threading.Thread(target=monitor_auth_url_updates, daemon=True).start()

def handle_status_and_alerts():
    global last_expires_at, alert_5_sent, alert_30_sent, alert_4_sent, alert_sent
    global last_alert_time, last_status, alert_missed_count, missed_alert_last_time, auth_url
    current_time = int(time.time())
    expires_at, status = get_status()
    diff = expires_at - current_time
    msg = None

    if expires_at != last_expires_at:
        reset_alerts()
        last_expires_at = expires_at

    if time.time() - last_alert_time > 20:
        if 0 <= diff < 310 and not alert_5_sent:
            auth_url = get_live_auth_url()
            nodename = get_nodename()
            update_phone_if_needed()
            msg = format_message(5, expires_at)
            alert_5_sent = True
        elif 310 <= diff < 1810 and not alert_30_sent:
            auth_url = get_live_auth_url()
            nodename = get_nodename()
            update_phone_if_needed()
            success_msg = f" {nodename}) - {auth_url} - متبقي 30 دقيقة!"
            send_telegram_error(success_msg)
            msg = format_message(30, expires_at)
            alert_30_sent = True
        elif 1810 <= diff < 6400 and not alert_4_sent:
            auth_url = get_live_auth_url()
            nodename = get_nodename()
            update_phone_if_needed()
            msg = format_message(240, expires_at)
            alert_4_sent = True
        if msg:
            send_message_to_server(msg, phone)
            last_alert_time = time.time()

    if status == "Inactive" and not alert_sent and alert_missed_count < 3:
        if missed_alert_last_time == 0 or current_time - missed_alert_last_time >= 600:
            auth_url = get_live_auth_url()
            nodename = get_nodename()
            update_phone_if_needed()
            send_message_to_server(f"⏰ ({nodename}) - {auth_url} - 😰 يجب التصوير فورا😰", phone)
            success_msg = f" {nodename}) - {auth_url} - 😰 يجب التصوير فورا😰!"
            send_telegram_error(success_msg)
            alert_missed_count += 1
            missed_alert_last_time = current_time

    if last_status == "Inactive" and status == "Active":
        nodename = get_nodename()
        update_phone_if_needed()
        send_message_to_server(f"🎉 {nodename} ✅ 😍🫡تم التوثيق بنجاح! نراك بعد أسبوع إن شاء الله.😍🫡", phone)
        success_msg = f"🎉 {nodename} ✅ تم التوثيق بنجاح!"
        send_telegram_error(success_msg)
        alert_sent = True

    last_status = status

def main_loop():
    while True:
        try:
            handle_status_and_alerts()
            handle_status_and_alerts2()
            schedule.run_pending()
            time.sleep(1)
        except Exception as e:
            send_telegram_error(f"🚨 خطأ غير متوقع في main_loop:\n{e}")
            logging.exception("استثناء غير متوقع")

if __name__ == "__main__":
    nodename = get_nodename()
    auth_url = get_live_auth_url()
    time_started = time.time()
    main_loop()

import os
import json
import time
import paramiko
import requests
import logging
from pathlib import Path

# إعداد السجل
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# بيانات السيرفر
remote_ip = "152.53.84.199"
remote_user = "root"
remote_password = "4Y8z1eblEJ"
remote_file_path = "/root/whatsapp-bot/what.txt"

# ملفات Humanode
log_file_path = "/root/.humanode/workspaces/default/node/logs.txt"
workspace_file = Path("/root/.humanode/workspaces/default/workspace.json")

# ----------------------------

def get_nodename():
    try:
        with open(workspace_file) as f:
            data = json.load(f)
        nodename = data.get("nodename", "Unknown")
        logging.info(f"📛 اسم النود: {nodename}")
        return nodename
    except Exception as e:
        logging.error(f"❌ خطأ في قراءة nodename: {e}")
        return "Unknown"

def fetch_phone_number(nodename):
    try:
        url = f"http://152.53.84.199/read_csv.php?node={nodename}"
        res = requests.get(url)
        logging.info(f"📡 الطلب إلى: {url}")
        logging.info(f"📨 الرد الخام: {res.text}")  # لرؤية الاستجابة مباشرة

        data = res.json()
        phone = data.get("phone")
        if phone:
            logging.info(f"📞 رقم الهاتف المستخرج: {phone}")
        else:
            logging.warning("❗ لم يتم العثور على مفتاح 'phone' في الرد")
        return phone
    except Exception as e:
        logging.warning(f"⚠️ فشل في جلب رقم الهاتف من السيرفر: {e}")
        return None

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
        logging.error(f"⚠️ خطأ في إرسال الرسالة عبر SFTP: {e}")

def get_auth_url():
    try:
        result = os.popen("/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json").read().strip()
        logging.info(f"✅ auth_url: {result}")
        return result
    except Exception as e:
        logging.warning(f"❌ فشل في جلب auth_url: {e}")
        return None

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
            logging.warning("⚠️ فشل في جلب حالة التوثيق. إعادة المحاولة...")
            time.sleep(19)

# ----------------------------

# التحضير
nodename = get_nodename()
phone = fetch_phone_number(nodename) or "905386293162"

if not phone:
    logging.error("❌ لم يتم العثور على رقم الهاتف. تحقق من read_csv.php أو اسم النود.")
    exit(1)  # أوقف السكربت حتى تصلح المشكلة

auth_url = get_auth_url()

if auth_url:
    enroll_url = auth_url
    authenticate_url = auth_url

    send_message_to_server(f"🔗{nodename}مرحبا هذا الرابط الاول لا تقم بالدخول عليه الا في حال قمنا باخبارك : {enroll_url}", phone)
    
    logging.info("📄 تم إرسال رابط التسجيل. نراقب اللوق من البداية...")

    found = False

    while not found:
        try:
            with open(log_file_path, 'r') as f:
                lines = f.readlines()
                for line in lines:
                    if "Bioauth flow - enrolling complete" in line:
                        logging.info("✅ تم العثور على الجملة المطلوبة!")
                        send_message_to_server(f"🔐 {nodename} تم التوثيق الأول بنجاح، للدخول إلى المرحلة الثانية استخدم الرابط التالي ثم الضغط على الزر الاخضر {authenticate_url}", phone)
                        found = True
                        break
        except Exception as e:
            logging.warning(f"⚠️ خطأ أثناء قراءة اللوق: {e}")

        if not found:
            time.sleep(3)

    # ننتظر حالة التوثيق
    logging.info("⌛ ننتظر حتى يتم التوثيق...")

    last_status = "Inactive"
    alert_sent = False

    while not alert_sent:
        _, status = get_status()
        if last_status == "Inactive" and status == "Active":
            updated_phone = fetch_phone_number(nodename) or phone
            send_message_to_server(f"🎉 {nodename} ✅ تم التوثيق بنجاح! نراك بعد أسبوع إن شاء الله.", updated_phone)
            alert_sent = True
        last_status = status
        if not alert_sent:
            time.sleep(10)

    logging.info("🎯 اكتمل التوثيق. سيتم إنهاء السكربت الآن.")



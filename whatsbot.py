import os
import json
import requests
import time
import paramiko
import schedule
import pytz
from datetime import datetime
import subprocess

# تفاصيل الملف
workspace_file = "/root/.humanode/workspaces/default/workspace.json"

server_ip = requests.get("https://ifconfig.me").text

# جلب الرابط من الأداة مع إعادة المحاولة بشكل مستمر
def get_auth_url():
    while True:
        try:
            auth_url = os.popen("/root/.humanode/workspaces/default/./humanode-peer bioauth auth-url --rpc-url-ngrok-detect --chain /root/.humanode/workspaces/default/chainspec.json").read().strip()
            if auth_url:
                print(f"✅ تم الحصول على auth_url بنجاح: {auth_url}")
                return auth_url
            else:
                print("⚠️ فشل في جلب auth_url، إعادة المحاولة بعد 5 ثوانٍ...")
        except Exception as e:
            print(f"❌ خطأ أثناء جلب auth_url: {e}, إعادة المحاولة بعد 5 ثوانٍ...")
        time.sleep(5)

auth_url = get_auth_url()

# قراءة اسم النود من الملف مع التعامل مع الأخطاء
def get_nodename():
    try:
        with open(workspace_file, 'r') as f:
            workspace_data = json.load(f)
        return workspace_data.get("nodename", "Unknown")
    except Exception as e:
        print(f"❌ حدث خطأ أثناء قراءة اسم النود: {e}")
        return "Unknown"

nodename = get_nodename()

# دالة للحصول على حالة التوثيق بشكل مستمر
def get_status():
    while True:
        try:
            status_response = requests.post(
                "http://127.0.0.1:9944",
                headers={"Content-Type": "application/json"},
                data=json.dumps({"jsonrpc": "2.0", "method": "bioauth_status", "params": [], "id": 1})
            )
            
            
            
            # تحويل الاستجابة إلى JSON
            try:
                status_data = status_response.json()
            except json.JSONDecodeError:
                print("⚠️ فشل في تحويل الاستجابة إلى JSON. إعادة المحاولة...")
                time.sleep(5)
                continue  # إعادة المحاولة في حال كانت الاستجابة غير صالحة

            # التحقق من أن الاستجابة تحتوي على نتيجة صالحة
            if isinstance(status_data, dict) and "result" in status_data and isinstance(status_data["result"], dict):
                active_data = status_data["result"].get("Active", {})
                expires_at = active_data.get("expires_at", 0)

                # التحقق من أن expires_at صالح
                if isinstance(expires_at, (int, float)) and expires_at > 0:
                    return int(expires_at / 1000)  # تحويل إلى ثوانٍ
                else:
                    print("⚠️ لم يتم العثور على `expires_at` صالح. إعادة المحاولة...")
            else:
                print("⚠️ الاستجابة لا تحتوي على نتيجة صالحة. إعادة المحاولة...")

        except (requests.RequestException, json.JSONDecodeError) as e:
            print(f"❌ خطأ أثناء جلب البيانات: {e}. إعادة المحاولة...")

        time.sleep(19)  # الانتظار قبل إعادة المحاولة

expires_at = get_status()

# حالة التنبيه لمنع الإرسال المتكرر
alert_30_sent = False
alert_5_sent = False
alert_4_sent = False  # متغير جديد للـ 4 ساعات
alert_sent = False
last_reset_time = time.time()

# مسار ملف السجل
log_file_path = "/root/.humanode/workspaces/default/node/logs.txt"
remote_ip = "152.53.84.199"
remote_user = "root"
remote_password = "4Y8z1eblEJ"
remote_file_path = "/root/whatsapp-bot/what.txt"
phone = 905312395611

# وظيفة لقراءة الملف والتحقق من كلمة "completed"
def check_log_for_completed():
    global alert_sent
    if alert_sent:
        return
    try:
        with open(log_file_path, 'r') as log_file:
            content = log_file.read()
        if "authentication complete" in content:
            update_phone_if_needed()
            print("عملية التوثيق تمت بنجاح!")
            send_message_to_server(f"{nodename} تمت عملية التوثيق بنجاح نراك بعد أسبوع", phone)
            os.popen("> /root/.humanode/workspaces/default/node/logs.txt")
            alert_sent = True
            schedule.every().day.at("02:00").do(reset_alert_sent)
            schedule.every().day.at("02:00").do(reset_alert_30_sent)
            schedule.every().day.at("02:00").do(reset_alert_5_sent)
            schedule.every().day.at("02:00").do(reset_alert_4_sent)
    except Exception as e:
        print(f"حدث خطأ أثناء قراءة الملف: {e}")

# وظيفة لإرسال رسالة إلى السيرفر الآخر عبر SFTP
def send_message_to_server(message, phone):
    try:
        # الحصول على التوقيت الحالي في تركيا
        turkey_tz = pytz.timezone("Europe/Istanbul")
        current_time = datetime.now(turkey_tz).strftime("%H:%M")
        message = f"{phone} {message} "

        # إعداد الاتصال بـ SFTP
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh_client.connect(remote_ip, username=remote_user, password=remote_password)

        # فتح قناة SFTP
        sftp = ssh_client.open_sftp()

        # قراءة محتوى الملف القديم
        with sftp.open(remote_file_path, 'r') as remote_file:
            existing_content = remote_file.read().decode()

        # إضافة الرسالة في بداية المحتوى
        new_content = message + '\n' + existing_content

        # كتابة المحتوى الجديد في الملف
        with sftp.open(remote_file_path, 'w') as remote_file:
            remote_file.write(new_content)

        # إغلاق الاتصال
        time.sleep(5)
        sftp.close()
        ssh_client.close()

        print(f"تم إرسال الرسالة بنجاح عبر SFTP: {message}")
    except Exception as e:
        print(f"حدث خطأ أثناء الاتصال بـ SFTP: {e}")

# وظائف إعادة تعيين حالة التنبيهات
def reset_alert_sent():
    global alert_sent
    alert_sent = False
    print("تم إعادة تعيين حالة الإرسال.")

def reset_alert_30_sent():
    global alert_30_sent
    alert_30_sent = False
    print("تم إعادة تعيين alert_30_sent.")

def reset_alert_5_sent():
    global alert_5_sent
    alert_5_sent = False
    print("تم إعادة تعيين alert_5_sent.")

def reset_alert_4_sent():
    global alert_4_sent
    alert_4_sent = False
    print("تم إعادة تعيين alert_4_sent.")

# تحديث الرقم بشكل دائم عند تحقق الشرط
def fetch_phone_number(nodename):
    try:
        response = requests.get(f"http://152.53.84.199/read_csv.php?node={nodename}")
        if response.status_code == 200:
            data = response.json()
            if "phone" in data:
                return data["phone"]
            else:
                print(f"❌ خطأ: {data.get('error', 'لم يتم العثور على الرقم')}")
        else:
            print("❌ فشل في الاتصال بالسيرفر")
    except Exception as e:
        print(f"حدث خطأ أثناء جلب البيانات: {e}")
    return None

# تحديث الرقم بشكل دائم
def update_phone_if_needed():
    global phone
    phone_number = fetch_phone_number(nodename)
    if phone_number:
        phone = phone_number
        print(f"تم تحديث الرقم إلى: {phone}")
    else:
        print("لم يتم تحديث الرقم باستخدام القيمة الافتراضية.")

# بدء العملية الرئيسية
while True:
    current_timestamp = int(time.time())
    expires_at = get_status()
    difference = (expires_at - current_timestamp)

    message = None
    if 0 < difference < 1810 and not alert_30_sent:  # 1800 seconds = 30 minutes
        remaining_time = datetime.fromtimestamp(expires_at).astimezone(pytz.timezone("Europe/Istanbul")).strftime("%H:%M")
        message = f" {nodename} ({server_ip}) ({remaining_time} يجب التصوير في هذه الساعة ) {auth_url}"
        alert_30_sent = True
        print(f"تم إرسال التنبيه للـ 30 دقيقة ({remaining_time})")
        update_phone_if_needed()

    elif 0 < difference < 310 and not alert_5_sent:  # 300 seconds = 5 minutes
        remaining_time = datetime.fromtimestamp(expires_at).astimezone(pytz.timezone("Europe/Istanbul")).strftime("%H:%M")
        message = f" {nodename} ({server_ip}) ({remaining_time} يجب التصوير في هذه الساعة ) {auth_url} "
        alert_5_sent = True
        update_phone_if_needed()
    elif 0 < difference < 14400 and not alert_4_sent:  # 14400 seconds = 4 hours
        remaining_time = datetime.fromtimestamp(expires_at).astimezone(pytz.timezone("Europe/Istanbul")).strftime("%H:%M")
        message = f" {nodename} ({server_ip}) ({remaining_time} يجب التصوير في هذه الساعة ) {auth_url} "
        alert_4_sent = True
        print(f"تم إرسال التنبيه للـ 4 ساعات ({remaining_time})")
        update_phone_if_needed()

    if message:
        send_message_to_server(message, phone)

    check_log_for_completed()
    schedule.run_pending()
    time.sleep(20)

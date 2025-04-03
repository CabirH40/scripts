import os
import time
import paramiko
import logging

# إعداد السجل
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# بيانات الإرسال
remote_ip = "152.53.84.199"
remote_user = "root"
remote_password = "4Y8z1eblEJ"
remote_file_path = "/root/whatsapp-bot/what.txt"
phone = "905312395611"

log_file_path = "/root/.humanode/workspaces/default/node/logs.txt"

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

# إرسال الرابط الأول فقط
auth_url = get_auth_url()

if auth_url:
    enroll_url = auth_url + "/setup-node/enroll"
    authenticate_url = auth_url + "/authenticate"

    # أرسل رابط التسجيل
    send_message_to_server(f"🔗 رابط التسجيل: {enroll_url}", phone)
    logging.info("📄 تم إرسال رابط التسجيل. نراقب اللوق من البداية...")

    found = False

    while not found:
        try:
            with open(log_file_path, 'r') as f:
                lines = f.readlines()
                for line in lines:
                    if "Bioauth flow - enrolling complete" in line:
                        logging.info("✅ تم العثور على الجملة المطلوبة!")
                        send_message_to_server(f"🔐 رابط التوثيق: {authenticate_url}", phone)
                        found = True
                        break
        except Exception as e:
            logging.warning(f"⚠️ خطأ أثناء قراءة اللوق: {e}")

        if not found:
            time.sleep(3)

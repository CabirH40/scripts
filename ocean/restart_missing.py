import requests
import subprocess
import os
import sys
import time
import threading
import logging

# إعداد اللوج
def setup_logger():
    logger = logging.getLogger("RestartLogger")
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    return logger

# إرسال إشعارات تيليجرام
def send_telegram(message):
    TOKEN = "8156961663:AAGAETb8hWNukSsLoTViw12bb70QrMQs8xE"
    CHAT_ID = "-1002493763559"
    url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
    try:
        requests.post(url, data={"chat_id": CHAT_ID, "text": message})
    except:
        pass

# الحصول على IP العام
def get_public_ip():
    try:
        return requests.get("https://api.ipify.org").text
    except:
        return "unknown"

# مؤقت الإيقاف الذاتي بعد ساعتين و50 دقيقة
def kill_after_timeout(timeout_sec=10200):
    def killer():
        time.sleep(timeout_sec)
        send_telegram("⏱️{public_ip} السكريبت تجاوز المدة المحددة وتم إيقافه تلقائياً")
        os._exit(0)
    threading.Thread(target=killer, daemon=True).start()

# جلب النودات من الـ API
def fetch_nodes(ip):
    url = f"https://incentive-backend.oceanprotocol.com/nodes?size=350&search={ip}"
    try:
        r = requests.get(url)
        r.raise_for_status()
        return r.json().get("nodes", [])
    except:
        return []

# البحث عن النودات المفقودة محلياً
def find_missing_ports(nodes):
    ports = {n.get('_source', {}).get('ipAndDns', {}).get('port') for n in nodes if n.get('_source', {}).get('ipAndDns', {}).get('port') is not None}
    api_nodes = {f"node-{(p - 1026) // 5}" for p in ports}
    local_nodes = {f for f in os.listdir("/root/docker-compose-files") if f.startswith("node-")}
    missing = local_nodes - api_nodes
    return [int(n.split('-')[1]) * 5 + 1026 for n in missing]

# تنفيذ restart
def execute_restart(port, logger):
    node_num = (port - 1026) // 5
    path = f"/root/docker-compose-files/node-{node_num}"
    if not os.path.isfile(os.path.join(path, "docker-compose.yml")):
        logger.warning(f"❌ لم يتم العثور على الملف في: {path}")
        return

    try:
        subprocess.run(["docker", "compose", "restart"], cwd=path, timeout=400)
        logger.info(f"✅ تم إعادة تشغيل: node-{node_num}")
        send_telegram(f"🔁{public_ip} تمت إعادة تشغيل: node-{node_num}/docker-compose.yml")
    except:
        logger.error(f"⚠️ فشل في إعادة تشغيل: node-{node_num}")

# البرنامج الرئيسي
def main():
    logger = setup_logger()
    kill_after_timeout()
    public_ip = get_public_ip()
    send_telegram(f"🚀 السكريبت missing بدأ على IP: {public_ip}")

    nodes = fetch_nodes(public_ip)
    ports = find_missing_ports(nodes)

    for port in ports:
        execute_restart(port, logger)

    send_telegram("✅ السكريبت missing انتهى")

if __name__ == "__main__":
    main()

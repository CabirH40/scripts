#!/bin/bash
set -euo pipefail

# تعريف المتغيرات
SERVICE_NAME="http-server.service"
SCRIPT_PATH="/root/script/get_auth_url.sh"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

# ✅ إذا الخدمة مثبتة والسكريبت موجود، لا تعمل شيء
if systemctl is-enabled --quiet "$SERVICE_NAME" && [ -s "$SCRIPT_PATH" ]; then
  echo "✅ الخدمة $SERVICE_NAME و $SCRIPT_PATH موجودة. لا حاجة للتثبيت، يتم التخطي."
  exit 0
fi

echo "🧪 الخدمة غير موجودة أو السكربت ناقص. جاري التثبيت..."

# get_auth_url.sh scriptini indir
echo "get_auth_url.sh indiriliyor..."
wget -q -O /root/script/get_auth_url.sh "https://github.com/CabirH40/script.sh/raw/main/get_auth_url.sh" || true

# إذا التحميل فشل أو الملف فارغ، اتركه كما هو (قد يكون تم تجهيزه محلياً مسبقًا)
if [ ! -s /root/script/get_auth_url.sh ]; then
  echo "⚠️ get_auth_url.sh غير متاح من المصدر الخارجي. سيتم استخدام النسخة المحلية إن وجدت."
fi

# get_auth_url.sh çalıştırılabilir yap
echo "get_auth_url.sh çalıştırılabilir yapılıyor..."
chmod +x /root/script/get_auth_url.sh

# website dizinini oluştur
echo "Website dizini oluşturuluyor..."
mkdir -p /root/script/website

# start_http_server.sh scriptini oluştur
echo "start_http_server.sh oluşturuluyor..."
cat << 'EOF' > /root/script/start_http_server.sh
#!/bin/bash
cd /root/script/website
python3 -m http.server 2025
EOF

# start_http_server.sh çalıştırılabilir yap
chmod +x /root/script/start_http_server.sh

# get_auth_url.sh için cron görevi ekle (her dakika çalıştır)
echo "Cron görevi ekleniyor..."
(
  crontab -l 2>/dev/null | grep -v -F "/root/script/get_auth_url.sh" || true
  echo "* * * * * /root/script/get_auth_url.sh"
) | crontab -

# http-server için systemd hizmet dosyasını oluştur
echo "http-server.service oluşturuluyor..."
cat << 'EOF' > "$SYSTEMD_SERVICE_FILE"
[Unit]
Description=Simple HTTP Server
After=network.target

[Service]
ExecStart=/root/script/start_http_server.sh
WorkingDirectory=/root/script/website
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# systemd hizmetini etkinleştir ve başlat
echo "Hizmet etkinleştiriliyor ve başlatılıyor..."
systemctl daemon-reload
systemctl enable http-server.service
systemctl start http-server.service

# Hizmetin durumu gösteriliyor
systemctl status http-server.service

echo "Kurulum tamamlandı!"
exit

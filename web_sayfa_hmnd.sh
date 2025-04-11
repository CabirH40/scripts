#!/bin/bash

# تعريف المتغيرات
SERVICE_NAME="http-server.service"
SCRIPT_PATH="/root/get_auth_url.sh"

# ✅ إذا الخدمة مثبتة والسكريبت موجود، لا تعمل شيء
if systemctl is-enabled --quiet "$SERVICE_NAME" && [ -f "$SCRIPT_PATH" ]; then
  echo "✅ الخدمة $SERVICE_NAME و $SCRIPT_PATH موجودة. لا حاجة للتثبيت، يتم التخطي."
  exit 0
fi

echo "🧪 الخدمة غير موجودة أو السكربت ناقص. جاري التثبيت..."

# get_auth_url.sh scriptini indir
echo "get_auth_url.sh indiriliyor..."
wget -O /root/get_auth_url.sh "https://github.com/CabirH40/script.sh/raw/main/get_auth_url.sh"

# get_auth_url.sh çalıştırılabilir yap
echo "get_auth_url.sh çalıştırılabilir yapılıyor..."
chmod +x /root/get_auth_url.sh

# website dizinini oluştur
echo "Website dizini oluşturuluyor..."
mkdir -p /root/website

# start_http_server.sh scriptini oluştur
echo "start_http_server.sh oluşturuluyor..."
cat << 'EOF' > /root/start_http_server.sh
#!/bin/bash
cd /root/website
python3 -m http.server 2025
EOF

# start_http_server.sh çalıştırılabilir yap
chmod +x /root/start_http_server.sh

# get_auth_url.sh için cron görevi ekle (her dakika çalıştır)
echo "Cron görevi ekleniyor..."
(crontab -l 2>/dev/null; echo "* * * * * /root/get_auth_url.sh") | crontab -

# http-server için systemd hizmet dosyasını oluştur
echo "http-server.service oluşturuluyor..."
cat << 'EOF' > /etc/systemd/system/http-server.service
[Unit]
Description=Simple HTTP Server
After=network.target

[Service]
ExecStart=/root/start_http_server.sh
WorkingDirectory=/root/website
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

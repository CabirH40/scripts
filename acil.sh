#!/bin/bash

# Hedef ağ arayüzü
INTERFACE="ens192"

# Ayarlanacak DNS adresleri
DNS1="1.1.1.1"
DNS2="8.8.8.8"

echo "🛠️ DNS ayarlanıyor: $INTERFACE arayüzü için..."
resolvectl dns "$INTERFACE" "$DNS1" "$DNS2"

echo "🌍 Search domain global olarak ayarlanıyor..."
resolvectl domain "$INTERFACE" "~."

echo "🔍 $INTERFACE arayüzünün mevcut durumu:"
resolvectl status "$INTERFACE"

echo "✅ DNS başarıyla uygulandı!"

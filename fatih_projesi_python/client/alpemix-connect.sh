#!/bin/bash
# Alpemix bağlantı bilgilerini al ve ekran görüntüsünü göster
# Kullanım: ./alpemix-connect.sh
# Bu script yerel makinede çalışır

echo "Alpemix bilgileri alınıyor..."

# Uzak makinede alpemix-info.sh çalıştır
ssh etap '/opt/fatih-client/alpemix-info.sh'

echo ""
echo "Ekran görüntüsü indiriliyor..."

# Screenshot'ı indir ve göster
scp etap:/tmp/alpemix_screenshot.png /tmp/alpemix.png 2>/dev/null

if [ -f /tmp/alpemix.png ]; then
    echo "Alpemix penceresi açılıyor..."
    xdg-open /tmp/alpemix.png 2>/dev/null &
else
    echo "Ekran görüntüsü indirilemedi."
fi

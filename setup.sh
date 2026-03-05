#!/bin/bash

# Fatih Client - Otomatik Kurulum ve Şifreleme (Obfuscation) Scripti
# Bu script sahadaki tahtalara tek tuşla kurulum yapmak için tasarlanmıştır.

echo "========================================================="
echo "        FATİH CLİENT OTOMATİK KURULUM SİSTEMİ            "
echo "========================================================="

# Root yetkisi kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "Lütfen bu scripti sudo ile çalıştırın: sudo ./setup.sh"
  exit 1
fi

echo "[1/6] Gerekli paketler yükleniyor..."
apt-get update -qq
apt-get install -y python3-pip python3-pyqt5 evdev
# Cython ve kaynak kurucuları yükle (kodu C'ye çevirip şifrelemek için)
apt-get install -y python3-pip python3-pyqt5 evdev python3-dev gcc
pip3 install Cython==3.0.11

echo "[2/6] Python kodları şifreleniyor (Obfuscation)..."
# Ana projenin olduğu dizine geç
cd "$(dirname "$0")"

# Eski derlemeleri temizle
rm -rf build/ fatih_projesi_python/client/client.c fatih_projesi_python/client/*.so 2>/dev/null

# Cython ile client.py'yi C uzantısına (.so) derle
python3 compile_client.py build_ext --inplace

if [ ! -f fatih_projesi_python/client/client*.so ]; then
    echo "❌ HATA: Kod şifreleme başarısız oldu!"
    exit 1
fi
echo "✅ Kodlar başarıyla şifrelendi (.so oluşturuldu)."

echo "[3/6] Sistem dosyaları hedefe kopyalanıyor..."
INSTALL_DIR="/opt/fatih-client"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/resources"

# Şifrelenmiş .so dosyasını kopyala
cp fatih_projesi_python/client/client*.so "$INSTALL_DIR/"

# Çalıştırmak için ufak bir main.py oluştur (sadece derlenmiş kütüphaneyi içe aktarır)
cat <<EOF > "$INSTALL_DIR/main.py"
import client
if __name__ == "__main__":
    pass # client.py zaten import anında çalışmaya başlıyorsa yeterlidir.
    # Eğer içerde if __name__ == "__main__": varsa, onu da manuel çağırmak gerekebilir:
    # Ancak Fatih Client genelde PyQt5'i doğrudan globalde veya kendi çağırdığı bir fonksiyonla başlatır.
EOF

# Not: client.py'nin sonundaki if __name__ == "__main__": bloğu varsa import'ta çalışmaz.
# Bu yüzden main.py içine o manuel çağrıyı ekliyoruz:
cat <<EOF > "$INSTALL_DIR/main.py"
import os
import sys

# Yolu ayarla ki kaynakları bulabilsin
os.chdir("/opt/fatih-client")

import client

if hasattr(client, 'main'):
    client.main()
elif hasattr(client, 'FatihClientApp'):
    # Zaten iceride importlanirken main execute edilmemisse (ki PyQt uygulamasinda edilir) 
    pass
EOF

# Kaynak dosyaları (görseller, ikonlar) kopyala
cp -r fatih_projesi_python/client/resources/* "$INSTALL_DIR/resources/" 2>/dev/null

# Varsayılan yapılandırma dosyasını kopyala
cp config.ini "$INSTALL_DIR/config.ini" 2>/dev/null

# uninstall.sh'i root dizinine veya güvenli bir yere kopyala
cp uninstall.sh /usr/local/bin/fatih-uninstall
chmod 700 /usr/local/bin/fatih-uninstall

# İzinleri ayarla
chmod -R 755 "$INSTALL_DIR"
chown -R root:root "$INSTALL_DIR"

echo "[4/6] Kurum Kodu (Corporate Code) ayarlanıyor..."
read -p "Lütfen Kurum Kodunu Girin: " CORPORATE_CODE
if [ ! -z "$CORPORATE_CODE" ]; then
    # Kurum kodunu config.ini içine yaz (Eğer config parser kullanılabilirse)
    # Basit bir replace işlemi:
    sed -i "s/^corporate_code =.*/corporate_code = $CORPORATE_CODE/g" "$INSTALL_DIR/config.ini" 2>/dev/null || echo "corporate_code = $CORPORATE_CODE" >> "$INSTALL_DIR/config.ini"
    
    # Kullanıcı klasörüne kopyala
    mkdir -p /home/etapadmin/.config/fatih-client
    cp "$INSTALL_DIR/config.ini" /home/etapadmin/.config/fatih-client/config.ini
    chown -R etapadmin:etapadmin /home/etapadmin/.config/fatih-client
    echo "✅ Kurum kodu ayarlandı: $CORPORATE_CODE"
fi

echo "[5/6] Otomatik Başlatma (Autostart) yapılandırılıyor..."
AUTOSTART_DIR="/etc/xdg/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/fatih-client-autostart.desktop"

mkdir -p "$AUTOSTART_DIR"
cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Name=Fatih Client
Comment=Akıllı Tahta Kilit Sistemi
Exec=/usr/bin/python3 $INSTALL_DIR/main.py
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=false
EOF

chmod 644 "$AUTOSTART_FILE"

echo "[6/6] Arka plan servisleri temizleniyor..."
pkill -9 -f client.py 2>/dev/null

echo "========================================================="
echo "✅ KURULUM TAMAMLANDI!"
echo "Sistem başarıyla kuruldu ve kodlar şifrelendi."
echo "Tahtayı test etmek için yeniden başlatmanız önerilir."
echo "Komut: sudo reboot"
echo "========================================================="

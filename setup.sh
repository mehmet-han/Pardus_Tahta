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
apt-get update -qq || echo "Uyarı: Depolar güncellenirken hata oluştu, devam ediliyor..."
# Gerekli kütüphaneler ve Cython için kaynak kurucuları yükle
apt-get install -y python3-pip python3-pyqt5 python3-dev gcc python3-setuptools python3-evdev || echo "Uyarı: Bazı apt paketleri bulunamadı, pip3 ile kurulmaya çalışılacak..."
pip3 install Cython==3.0.11 setuptools evdev --break-system-packages || pip3 install Cython==3.0.11 setuptools evdev

echo "[2/6] Python kodları şifreleniyor (Obfuscation)..."
# Ana projenin olduğu dizine geç
cd "$(dirname "$0")"

# Eski derlemeleri temizle
rm -rf build/ fatih_projesi_python/client/client.c fatih_projesi_python/client/*.so 2>/dev/null

# Cython ile client.py'yi C uzantısına (.so) derle
python3 compile_client.py build_ext --inplace

# Dosyayı bul ve ana dizine (.so olarak) al
COMPILED_FILE=$(find . -name "client*.so" -print -quit)

if [ -z "$COMPILED_FILE" ]; then
    echo "❌ HATA: Kod şifreleme başarısız oldu! .so dosyası bulunamadı."
    exit 1
fi

echo "✅ Kodlar başarıyla şifrelendi (.so oluşturuldu: $COMPILED_FILE)."

echo "[3/6] Sistem dosyaları hedefe kopyalanıyor..."
INSTALL_DIR="/opt/fatih-client"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/resources"

# Temizlik: Eski derlenmemiş script varsa sil (python'un .py'yi öncelikli yüklemesini engellemek için)
rm -f "$INSTALL_DIR/client.py" 2>/dev/null

# Şifrelenmiş .so dosyasını kopyala
cp "$COMPILED_FILE" "$INSTALL_DIR/"

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

# Tüm zorunlu değişkenleri barındıran tam teşekküllü varsayılan config'i oluştur:
# ÖNEMLİ: API URL, kullanıcı adı, şifre ve user-agent C# ClassVariable.cs ile birebir aynı olmalıdır!
cat <<EOF > "$INSTALL_DIR/config.ini"
[settings]
api_url = https://api.mebre.com.tr/v4/s_brt.php
wb_user = hcrKd_r
wb_pass = B1Mu?WjG!Ga6
user_agent = agent_SmartBoart
board_id = 0
version = V2.13
sub_version = 1
corporate_code = ${CORPORATE_CODE:-0}
ntp_servers = time.windows.com,time.google.com,time.cloudflare.com,time.apple.com
EOF

if [ ! -z "$CORPORATE_CODE" ]; then
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

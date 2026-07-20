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

echo "[1/7] Gerekli paketler yükleniyor..."
apt-get update -qq || echo "Uyarı: Depolar güncellenirken hata oluştu, devam ediliyor..."
# Gerekli kütüphaneler ve Cython için kaynak kurucuları yükle
apt-get install -y python3-pip python3-pyqt5 python3-dev gcc python3-setuptools python3-evdev || echo "Uyarı: Bazı apt paketleri bulunamadı, pip3 ile kurulmaya çalışılacak..."
pip3 install Cython==3.0.11 setuptools evdev --break-system-packages || pip3 install Cython==3.0.11 setuptools evdev

echo "[2/7] Python kodları şifreleniyor (Obfuscation)..."
# Ana projenin olduğu dizine geç
cd "$(dirname "$0")"

# Git'ten en son sürümü çek (Eğer çalıştırılan dizin git reposu ise)
if [ -d ".git" ]; then
    echo "Git reposu algılandı, güncellemeler çekiliyor..."
    git pull origin main || echo "Uyarı: git pull başarısız, yerel dosyalarla devam edilecek."
fi

# Eski derlemeleri kök dizinde ve client klasöründe tamamen temizle
rm -rf build/ fatih_projesi_python/client/client.c fatih_projesi_python/client/*.so *.so 2>/dev/null

# Cython ile client.py'yi C uzantısına (.so) derle
python3 compile_client.py build_ext --inplace

# Derlenen .so dosyasını bul (önceki adımda eski .so dosyaları zaten silindiği için güvenlidir)
COMPILED_FILE=$(find . -name "client*.so" -print -quit)

if [ -z "$COMPILED_FILE" ]; then
    echo "❌ HATA: Kod şifreleme başarısız oldu! .so dosyası bulunamadı."
    exit 1
fi

echo "✅ Kodlar başarıyla şifrelendi (.so oluşturuldu: $COMPILED_FILE)."

echo "[3/7] Sistem dosyaları hedefe kopyalanıyor..."
INSTALL_DIR="/opt/fatih-client"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/resources"

# Temizlik: Eski derlenmemiş script varsa sil (python'un .py'yi öncelikli yüklemesini engellemek için)
rm -f "$INSTALL_DIR/client.py" 2>/dev/null

# Şifrelenmiş .so dosyasını kopyala
cp "$COMPILED_FILE" "$INSTALL_DIR/"

# Çalıştırmak için ufak bir main.py oluştur (sadece derlenmiş kütüphaneyi içe aktarır)
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

# Versiyon dosyasını kopyala
cp fatih_projesi_python/client/version.txt "$INSTALL_DIR/version.txt" 2>/dev/null

# uninstall.sh'i root dizinine veya güvenli bir yere kopyala
cp uninstall.sh /usr/local/bin/fatih-uninstall
chown root:root /usr/local/bin/fatih-uninstall
chmod 700 /usr/local/bin/fatih-uninstall

# --- Uzaktan kaldirma icin sinirli sudo yetkisi ---
# Istemci etapadmin olarak calisiyor; kaldirma ise root isi. Bu kural olmadan
# ynt5'ten gelen "programi kaldir" komutu ACK'leniyor ama HICBIR SEY silinmiyordu
# (Errno 13). Yetki BILEREK dar tutuldu: sadece bu tek betik, baska hicbir komut.
# Betik root:700 oldugu icin etapadmin ICERIGINI DEGISTIREMEZ, yalnizca calistirabilir.
# Bedeli kabul edildi: tahtada terminale erisebilen biri kaldirmayi tetikleyebilir —
# asil koruma kiosk'un terminali kapatmasi.
_SUDOERS_FILE="/etc/sudoers.d/fatih-client"
echo "etapadmin ALL=(root) NOPASSWD: /usr/local/bin/fatih-uninstall" > "$_SUDOERS_FILE"
chmod 440 "$_SUDOERS_FILE"
chown root:root "$_SUDOERS_FILE"
# Bozuk bir sudoers dosyasi TUM sudo'yu kilitler -> dogrula, gecersizse geri al.
if visudo -c -f "$_SUDOERS_FILE" >/dev/null 2>&1; then
    echo "  ✅ Uzaktan kaldırma yetkisi tanımlandı (yalnızca fatih-uninstall)"
else
    rm -f "$_SUDOERS_FILE"
    echo "  ⚠ sudoers kuralı geçersiz, kaldırıldı — uzaktan kaldırma çalışmayacak."
fi

# İzinleri ayarla
chmod -R 755 "$INSTALL_DIR"
chown -R root:root "$INSTALL_DIR"

echo "[4/7] Kurum Kodu (Corporate Code) ayarlanıyor..."
read -p "Lütfen Kurum Kodunu Girin: " CORPORATE_CODE

# Eski ayarları korumak için yapılandırma dosyasını oku
EXISTING_CONFIG="/home/etapadmin/.config/fatih-client/config.ini"
BOARD_ID="0"
BOARD_NAME="Pardus Board"
ADMIN_PASSWORD="803580"
PASSWORD_CHANGED="false"
DEVICE_TOKEN=""

if [ -f "$EXISTING_CONFIG" ]; then
    BOARD_ID=$(sed -nr 's/^board_id\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG")
    BOARD_NAME=$(sed -nr 's/^board_name\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG")
    ADMIN_PASSWORD=$(sed -nr 's/^admin_password\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG")
    PASSWORD_CHANGED=$(sed -nr 's/^password_changed\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG")
    # v6: zaten tanitilmis bir tahtaya yeniden kurulum yapiliyorsa token'i KORU;
    # silinirse tahta kimliksiz kalir ve tekrar tanitilmasi gerekir.
    DEVICE_TOKEN=$(sed -nr 's/^device_token\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG")

    [ -z "$BOARD_ID" ] && BOARD_ID="0"
    [ -z "$BOARD_NAME" ] && BOARD_NAME="Pardus Board"
    [ -z "$ADMIN_PASSWORD" ] && ADMIN_PASSWORD="803580"
    [ -z "$PASSWORD_CHANGED" ] && PASSWORD_CHANGED="false"
fi

# --- v6: Enroll sirri (kurulum medyasindaki secret.txt) ---
# Sir teknisyene GOSTERILMEZ ve elle yazilmaz: setup.sh yanindaki secret.txt'ten okunur,
# config'e ENC'li gomulur ve tahta tanitilir tanitilmaz istemci tarafindan SILINIR.
# NOT: secret.txt USB'den SILINMEZ — ayni USB birden fazla tahtada kullaniliyor (bkz. doktor.sh).
ENROLL_SECRET_ENC=""
if [ -f "./secret.txt" ]; then
    _SECRET=$(tr -d ' \t\n\r' < ./secret.txt)
    if [ -n "$_SECRET" ]; then
        ENROLL_SECRET_ENC="ENC:$(printf '%s' "$_SECRET" | base64 -w0)"
        echo "  ✅ Kurulum sırrı okundu ve yapılandırmaya gömüldü."
    else
        echo "  ⚠ secret.txt boş! Tahta tanıtılamaz."
    fi
    _SECRET=""
elif [ -z "$DEVICE_TOKEN" ]; then
    echo "  ⚠ UYARI: secret.txt bulunamadı ve tahta daha önce tanıtılmamış."
    echo "     Tahta kilitli açılır. secret.txt'i setup.sh'ın yanına koyup tekrar kurun."
fi

# Credential'lar artık setup.sh veya config.ini'de barınmıyor. 
# Tamamen Fatih Client'in içinde XOR şifresiyle çalışma zamanında deşifre edilecek.

# Surum TEK KAYNAKTAN: paketteki version.txt. Burada SABIT yazmak, tahtanin sunucuya
# yanlis surum bildirmesine yol aciyordu ("V2.13" kalintisi) — kilit ekrani version.txt'ten
# okudugu icin dogru gorunuyor, sunucuya giden deger ise config.ini'den gelip bayat kaliyordu.
_PKG_VERSION=$(tr -d ' \t\n\r' < fatih_projesi_python/client/version.txt 2>/dev/null)
[ -z "$_PKG_VERSION" ] && _PKG_VERSION="V6.00.00"
echo "  → Kurulan sürüm: $_PKG_VERSION"

# Config dosyasını oluştur (Sadece yetkisiz kurum ve tahta bilgisi, parola saklaması BİTTİ)
cat <<EOF > "$INSTALL_DIR/config.ini"
[settings]
version = $_PKG_VERSION
sub_version = 1
corporate_code = ${CORPORATE_CODE:-0}
ntp_servers = time.windows.com,time.google.com,time.cloudflare.com,time.apple.com
board_id = $BOARD_ID
board_name = $BOARD_NAME
admin_password = $ADMIN_PASSWORD
password_changed = $PASSWORD_CHANGED
EOF

# Kosullu alanlar (bos degerle yazilirsa istemci bos sir/token okur -> ekle-veya-ekleme).
[ -n "$DEVICE_TOKEN" ] && echo "device_token = $DEVICE_TOKEN" >> "$INSTALL_DIR/config.ini"
[ -n "$ENROLL_SECRET_ENC" ] && echo "enroll_secret = $ENROLL_SECRET_ENC" >> "$INSTALL_DIR/config.ini"

if [ ! -z "$CORPORATE_CODE" ]; then
    # Kullanıcı klasörüne kopyala
    mkdir -p /home/etapadmin/.config/fatih-client
    cp "$INSTALL_DIR/config.ini" /home/etapadmin/.config/fatih-client/config.ini
    chown -R etapadmin:etapadmin /home/etapadmin/.config/fatih-client
    chmod 600 /home/etapadmin/.config/fatih-client/config.ini
    chmod 600 "$INSTALL_DIR/config.ini"
    echo "✅ Kurum kodu ayarlandı: $CORPORATE_CODE (Güvenlik yetkileri 600 olarak kilitlendi)"
fi

echo "[5/7] Otomatik Başlatma (Autostart) yapılandırılıyor..."
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

echo "[6/7] Arka plan servisleri temizleniyor..."
pkill -9 -f main.py 2>/dev/null
pkill -9 -f client.py 2>/dev/null

echo "[7/7] Güvenlik Temizliği ve Kullanıcı Ayarları Yapılıyor..."

# --- C# ve kaynak kodları temizle ---
if [ -d "Fatih_Projesi" ]; then
    rm -rf "Fatih_Projesi"
    echo "✅ C# Kaynak kodları güvenlik sebebiyle silindi."
fi

# Düz metin Python kodunu sil (derlenmiş .so kullanılacak)
rm -f "$INSTALL_DIR/client.py" 2>/dev/null
# USB üzerinden kurulum yaparken kaynak dosyayı silmeyin, aksi takdirde Faz2 ve Faz3 kurulumlarında cythonize hata verir!
# rm -f fatih_projesi_python/client/client.py 2>/dev/null
echo "✅ Kaynak Python kodu temizlendi (sadece derlenmiş .so mevcut)."

# --- Pardus Kullanıcı Şifrelerini Kaldır ---
echo "Kullanıcı şifreleri kaldırılıyor (Fatih kilit ekranı aktif)..."

if id "etapadmin" &>/dev/null; then
    passwd -d etapadmin 2>/dev/null && echo "  ✅ etapadmin şifresi kaldırıldı" || echo "  ⚠ etapadmin şifresi kaldırılamadı"
fi

if id "ogretmen" &>/dev/null; then
    passwd -d ogretmen 2>/dev/null && echo "  ✅ ogretmen şifresi kaldırıldı" || echo "  ⚠ ogretmen şifresi kaldırılamadı"
fi

if id "ogrenci" &>/dev/null; then
    passwd -d ogrenci 2>/dev/null && echo "  ✅ ogrenci şifresi kaldırıldı" || echo "  ⚠ ogrenci şifresi kaldırılamadı"
fi

# --- LightDM Otomatik Giriş Ayarı ---
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if [ -f "$LIGHTDM_CONF" ] || [ -d "/etc/lightdm" ]; then
    if grep -q "autologin-user" "$LIGHTDM_CONF" 2>/dev/null; then
        sed -i 's/^#*autologin-user=.*/autologin-user=etapadmin/' "$LIGHTDM_CONF"
    else
        if grep -q "\[Seat:\*\]" "$LIGHTDM_CONF" 2>/dev/null; then
            sed -i '/\[Seat:\*\]/a autologin-user=etapadmin' "$LIGHTDM_CONF"
        else
            mkdir -p /etc/lightdm
            cat <<LIGHTDM_EOF >> "$LIGHTDM_CONF"

[Seat:*]
autologin-user=etapadmin
LIGHTDM_EOF
        fi
    fi
    echo "  ✅ LightDM otomatik giriş ayarlandı (etapadmin)"
fi

# Cinnamon screensaver'ı devre dışı bırak
sudo -u etapadmin dbus-launch gsettings set org.cinnamon.desktop.screensaver lock-enabled false 2>/dev/null
sudo -u etapadmin dbus-launch gsettings set org.cinnamon.desktop.screensaver idle-activation-enabled false 2>/dev/null
echo "  ✅ Cinnamon ekran kilidi devre dışı bırakıldı"

echo "========================================================="
echo "✅ KURULUM TAMAMLANDI!"
echo "Sistem başarıyla kuruldu ve kodlar şifrelendi."
echo "Tahtayı test etmek için yeniden başlatmanız önerilir."
echo "Komut: sudo reboot"
echo "========================================================="
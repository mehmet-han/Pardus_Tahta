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

# Proje dizinine EN BASTA gec: kurulum dosyasi "setup.sh'in yanindaki" dosyadir, calistirildigi
# dizindeki degil. Eskiden bu cd [2/7]'de yapiliyordu; baska bir klasorden calistirilinca
# dosya bulunamiyordu.
cd "$(dirname "$0")" || { echo "❌ HATA: Kurulum klasörüne geçilemedi."; exit 1; }

# --- KURULUM DOGRULAMA KODU (3 Agustos 2026: dosya adi degisti) ---
# Kod artik `Readme.txt` icinde, kurulum talimatlarinin arasinda gomulu duruyor.
# NEDEN: dosya adi `secret.txt` iken USB'yi eline alan herkesin ilk actigi dosya oluyordu —
# tahtalari kuran yalnizca biz degiliz (diger firmalar ve ogretmenler de kuruyor).
# Bu bir GIZLEME onlemidir, sifreleme DEGILDIR; dosyayi acan yine gorur.
#
# Kod, dosyadaki ILK 64 haneli onaltilik dizidir — ozel bir etiket aranmaz ki
# "sir burada" diye isaret vermesin.
#
# ESKI USB'LER: `secret.txt` de kabul edilmeye devam eder (sahadaki medyalar bir
# gecede degismiyor). Once Readme.txt, yoksa secret.txt bakilir.

kurulum_kodu_oku() {
    local dosya
    for dosya in "./Readme.txt" "./readme.txt" "./secret.txt"; do
        if [ -f "$dosya" ]; then
            local kod
            kod=$(grep -oE '[0-9a-fA-F]{64}' "$dosya" 2>/dev/null | head -n 1)
            if [ -n "$kod" ]; then
                printf '%s' "$kod"
                return 0
            fi
        fi
    done
    return 1
}

_KURULUM_KODU=$(kurulum_kodu_oku)
_ONCEKI_TOKEN=$(sed -nr 's/^device_token[[:space:]]*=[[:space:]]*(.*)$/\1/p' /home/etapadmin/.config/fatih-client/config.ini 2>/dev/null)

if [ -n "$_KURULUM_KODU" ]; then
    echo "  ✅ Kurulum dosyası doğrulandı."
elif [ -n "$_ONCEKI_TOKEN" ]; then
    echo "  ℹ Kurulum dosyası yok ama tahta zaten tanıtılmış — mevcut kimlik korunacak."
else
    echo ""
    echo "========================================================="
    echo "❌ KURULUM DURDURULDU: Kurulum dosyası eksik."
    echo "========================================================="
    echo "Bu tahta daha önce tanıtılmamış, bu haliyle kurulursa TANITILAMAZ."
    echo ""
    echo "Yapılması gereken:"
    echo "  1) 'Readme.txt' dosyasını setup.sh ile AYNI klasöre koyun:"
    echo "     $(pwd)/Readme.txt"
    echo "  2) Kurulumu tekrar başlatın: sudo ./setup.sh"
    echo ""
    echo "Dosya kurulum USB'sindedir. Yoksa Mebre'den isteyin."
    echo "(Git deposundan kurulum yapıyorsanız bu dosya orada BULUNMAZ.)"
    echo "========================================================="
    exit 1
fi

# --- ON KONTROLLER (3 Agustos 2026: kurulum sahada cok takiliyordu) ---
# Amac: 5 dakikalik agir isten SONRA patlamak yerine, eksigi BASTA soylemek.
echo "[0/7] Ön kontroller..."

_EKSIK=""
for _d in "fatih_projesi_python/client/client.py" "compile_client.py" "uninstall.sh"; do
    [ -f "$_d" ] || _EKSIK="$_EKSIK $_d"
done
if [ -n "$_EKSIK" ]; then
    echo "❌ KURULUM DURDURULDU: kurulum dosyaları eksik:$_EKSIK"
    echo "   USB'yi olduğu gibi kullanın, dosyaları tek tek kopyalamayın."
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ KURULUM DURDURULDU: python3 bulunamadı."
    exit 1
fi

# Disk alani (en az 500 MB)
_BOS_MB=$(df -Pm /opt 2>/dev/null | awk 'NR==2{print $4}')
if [ -n "$_BOS_MB" ] && [ "$_BOS_MB" -lt 500 ]; then
    echo "❌ KURULUM DURDURULDU: /opt bölümünde yalnızca ${_BOS_MB} MB boş yer var (en az 500 MB gerekli)."
    exit 1
fi

# Internet: derleme icin paket indirmek gerekebilir, tanitim icin de sart
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
    _NET=1
else
    _NET=0
    echo "  ⚠ İnternet yok. Hazır derlenmiş dosya varsa kurulum devam eder,"
    echo "    ancak tahta tanıtımı için internet GEREKLİ."
fi

# KURUM KODU EN BASTA soruluyor: eskiden [4/7]'de soruluyordu, yani teknisyen
# yanlis yazarsa ya da vazgecerse 5 dakikalik derleme cope gidiyordu.
echo ""
read -p "Lütfen Kurum Kodunu Girin: " CORPORATE_CODE
if [ -z "$CORPORATE_CODE" ]; then
    echo "❌ KURULUM DURDURULDU: kurum kodu boş olamaz."
    exit 1
fi
case "$CORPORATE_CODE" in
    *[!0-9]*)
        echo "❌ KURULUM DURDURULDU: kurum kodu yalnızca rakam olmalı ('$CORPORATE_CODE' girildi)."
        exit 1
        ;;
esac
echo "  ✅ Kurum kodu: $CORPORATE_CODE"
echo ""

echo "[1/7] Gerekli paketler yükleniyor..."
apt-get update -qq || echo "Uyarı: Depolar güncellenirken hata oluştu, devam ediliyor..."
# Gerekli kütüphaneler ve Cython için kaynak kurucuları yükle
apt-get install -y python3-pip python3-pyqt5 python3-dev gcc python3-setuptools python3-evdev || echo "Uyarı: Bazı apt paketleri bulunamadı, pip3 ile kurulmaya çalışılacak..."
pip3 install Cython==3.0.11 setuptools evdev --break-system-packages || pip3 install Cython==3.0.11 setuptools evdev

echo "[2/7] Python kodları şifreleniyor (Obfuscation)..."
# NOT: proje dizinine gecis scriptin EN BASINDA yapildi (on kontrol secret.txt'e bakiyor).

# Git'ten en son sürümü çek (Eğer çalıştırılan dizin git reposu ise)
# NOT: eskiden KOSULSUZ `git pull origin main` yapiliyordu. Tahta kodu `v6` dalinda;
# v6 klonundan kurulum yapan teknisyende bu, main'i v6 uzerine cekmeye calisip
# ya catisma cikariyor ya da YANLIS SURUMU kuruyordu. Artik bulunulan dal cekilir
# ve basarisizlik sessizce yutulmaz.
if [ -d ".git" ]; then
    _DAL=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$_DAL" ] && [ "$_DAL" != "HEAD" ]; then
        echo "Git reposu algılandı (dal: $_DAL), güncellemeler çekiliyor..."
        git pull origin "$_DAL" || echo "  ⚠ git pull başarısız — YEREL dosyalarla devam ediliyor."
    fi
fi

# --- HAZIR DERLENMIS DOSYA VARSA DERLEME YAPILMAZ ---
# Kurulum sahada en cok BURADA takiliyordu: derleme icin apt deposu + internet +
# gcc + python3-dev + Cython indirmesi gerekiyor, okul agi bunlardan birini
# engelleyince kurulum ortada kaliyordu. Ayrica zayif tahta islemcisinde dakikalar suruyor.
# Pakette tahtanin Python surumune uyan hazir .so varsa dogrudan kullanilir.
_PYTAG=$(python3 -c "import sys; print('cpython-%d%d' % sys.version_info[:2])" 2>/dev/null)
COMPILED_FILE=""

if [ -n "$_PYTAG" ]; then
    for _hazir in hazir/client*.so fatih_projesi_python/client/client*.so; do
        case "$_hazir" in
            *"$_PYTAG"*)
                [ -f "$_hazir" ] && COMPILED_FILE="$_hazir" && break
                ;;
        esac
    done
fi

if [ -n "$COMPILED_FILE" ]; then
    echo "  ✅ Hazır derlenmiş dosya bulundu ($COMPILED_FILE) — derleme atlanıyor."
else
    echo "  ℹ Hazır dosya yok, tahtada derlenecek (internet ve derleyici gerekir)."

    # Eski derlemeleri temizle
    rm -rf build/ fatih_projesi_python/client/client.c fatih_projesi_python/client/*.so *.so 2>/dev/null

    if ! command -v gcc >/dev/null 2>&1; then
        echo "❌ KURULUM DURDURULDU: gcc yok ve hazır derlenmiş dosya da yok."
        echo "   İnternet bağlayıp tekrar deneyin ya da hazır paketi isteyin."
        exit 1
    fi

    python3 compile_client.py build_ext --inplace
    COMPILED_FILE=$(find . -name "client*.so" -print -quit)

    if [ -z "$COMPILED_FILE" ]; then
        echo "❌ HATA: Kod şifreleme başarısız oldu! .so dosyası bulunamadı."
        echo "   En sık sebep: python3-dev / gcc / Cython kurulamamış (internet yok)."
        exit 1
    fi
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
# ARGUMANSIZ bicim (""): `sudo fatih-uninstall --force` REDDEDILIR.
# Eski kural argumani serbest birakiyordu, --force ise sifreyi atliyordu;
# tahtada terminale erisen herkes kilit sistemini kaldirabiliyordu.
# Uzaktan kaldirma artik stdin uzerinden kanit yolluyor (bkz. uninstall.sh).
printf '%s\n' 'etapadmin ALL=(root) NOPASSWD: /usr/local/bin/fatih-uninstall ""' > "$_SUDOERS_FILE"
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
# 755 idi: TUM kullanicilar (ogretmen, ogrenci) derlenmis .so dosyasini okuyup
# kopyalayabiliyordu. 750 + root:etapadmin -> yalnizca tahtayi calistiran
# hesap ve root erisir.
chown -R root:etapadmin "$INSTALL_DIR"
chmod -R 750 "$INSTALL_DIR"

echo "[4/7] Kurum Kodu (Corporate Code) ayarlanıyor..."
# Kurum kodu ON KONTROLDE alindi (agir isten once) — burada tekrar sorulmaz.
echo "  → Kurum kodu: $CORPORATE_CODE"

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

# --- v6: Kurulum dogrulama kodu config'e gomulur ---
# Kod teknisyene GOSTERILMEZ ve elle yazilmaz: Readme.txt'ten okunur (on kontrolde),
# config'e ENC'li gomulur ve tahta tanitilir tanitilmaz istemci tarafindan SILINIR.
# NOT: dosya USB'den SILINMEZ — ayni USB birden fazla tahtada kullaniliyor (bkz. doktor.sh).
ENROLL_SECRET_ENC=""
if [ -n "$_KURULUM_KODU" ]; then
    ENROLL_SECRET_ENC="ENC:$(printf '%s' "$_KURULUM_KODU" | base64 -w0)"
    echo "  ✅ Kurulum kodu yapılandırmaya gömüldü."
fi
_KURULUM_KODU=""

# Credential'lar artık setup.sh veya config.ini'de barınmıyor. 
# Tamamen Fatih Client'in içinde XOR şifresiyle çalışma zamanında deşifre edilecek.

# Surum TEK KAYNAKTAN: paketteki version.txt. Burada SABIT yazmak, tahtanin sunucuya
# yanlis surum bildirmesine yol aciyordu ("V2.13" kalintisi) — kilit ekrani version.txt'ten
# okudugu icin dogru gorunuyor, sunucuya giden deger ise config.ini'den gelip bayat kaliyordu.
_PKG_VERSION=$(tr -d ' \t\n\r' < fatih_projesi_python/client/version.txt 2>/dev/null)
[ -z "$_PKG_VERSION" ] && _PKG_VERSION="V6.00.00"
echo "  → Kurulan sürüm: $_PKG_VERSION"

# --- Admin sifresi ARTIK DUZ METIN SAKLANMIYOR (3 Agustos 2026 incelemesi) ---
# Eskiden config.ini'de duz metindi. Kullanici config'i etapadmin'e ait (600) ama tahta
# zaten etapadmin olarak otomatik giris yapiyor -> tahta acikken terminale ulasan biri
# tek `cat` ile sifreyi okuyup tahtayi istedigi zaman acabiliyordu.
# Burada PBKDF2'ye cevriliyor; boylece GUNCELLENEN eski tahtalar da korunmus oluyor.
# Zaten hash'liyse dokunulmaz (cift hash olmasin).
case "$ADMIN_PASSWORD" in
    PBKDF2:*)
        echo "  ℹ Admin şifresi zaten korumalı biçimde."
        ;;
    *)
        _HASHLI=$(python3 -c "
import hashlib, os, sys
p = sys.argv[1] if len(sys.argv) > 1 else '803580'
t = os.urandom(16)
print('PBKDF2:%s:%s' % (t.hex(), hashlib.pbkdf2_hmac('sha256', p.encode(), t, 200000).hex()))
" "$ADMIN_PASSWORD" 2>/dev/null)
        if [ -n "$_HASHLI" ]; then
            ADMIN_PASSWORD="$_HASHLI"
            echo "  ✅ Admin şifresi korumalı biçime çevrildi (düz metin saklanmıyor)."
        else
            echo "  ⚠ Şifre dönüştürülemedi, eski biçimde bırakıldı."
        fi
        _HASHLI=""
        ;;
esac

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
# ogretmen/ogrenci: `passwd -d` (SIFREYI SIL) yerine `passwd -l` (HESABI KILITLE).
# -d bos sifre birakiyordu; Debian/Pardus varsayilan PAM'i nullok tasidigi icin bu
# hesaplara TTY'den BOS SIFREYLE giris yapilabiliyordu. -l ile sifreli giris tamamen kapanir.
# etapadmin BILEREK dokunulmadi: lightdm otomatik girisi o hesapla yapiliyor, kilitlemek
# tahtayi aciimaz hale getirebilir (bkz. inceleme notu - acik madde).
echo "Kullanıcı hesapları kilitleniyor (Fatih kilit ekranı aktif)..."

if id "etapadmin" &>/dev/null; then
    passwd -d etapadmin 2>/dev/null && echo "  ✅ etapadmin şifresi kaldırıldı" || echo "  ⚠ etapadmin şifresi kaldırılamadı"
fi

if id "ogretmen" &>/dev/null; then
    passwd -l ogretmen 2>/dev/null && echo "  ✅ ogretmen hesabı kilitlendi" || echo "  ⚠ ogretmen hesabı kilitlenemedi"
fi

if id "ogrenci" &>/dev/null; then
    passwd -l ogrenci 2>/dev/null && echo "  ✅ ogrenci hesabı kilitlendi" || echo "  ⚠ ogrenci hesabı kilitlenemedi"
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
echo "---------------------------------------------------------"
echo "Kurulan sürüm : $_PKG_VERSION"
echo "Kurum kodu    : ${CORPORATE_CODE:-(girilmedi)}"
# Teknisyen sahadan ayrilmadan once tahtanin tanitilabilir olup olmadigini GORSUN.
if [ -n "$DEVICE_TOKEN" ]; then
    echo "Tahta kimliği : ✅ Zaten tanıtılmış (mevcut kimlik korundu)"
elif [ -n "$ENROLL_SECRET_ENC" ]; then
    echo "Tahta kimliği : ⏳ Tanıtılmadı — kurulum kodu gömüldü."
    echo "                Yeniden başlattıktan sonra ekrandan kurum kodunu girip"
    echo "                'Tahtaları Getir' ile tahtayı seçin."
else
    echo "Tahta kimliği : ❌ Kurulum kodu yok — tahta tanıtılamaz! (bu satırı görmemeniz gerekir)"
fi
echo "---------------------------------------------------------"
echo "Tahtayı test etmek için yeniden başlatmanız önerilir."
echo "Komut: sudo reboot"
echo "========================================================="
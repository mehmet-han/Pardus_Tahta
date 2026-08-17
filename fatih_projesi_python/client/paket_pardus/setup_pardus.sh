#!/bin/bash
# ============================================================================
# MEBRE AKILLI TAHTA — PARDUS KURULUM (Nuitka .bin, §9.1 / v6)
# ============================================================================
# Eski setup.sh'tan FARK: sahada Cython/gcc DERLEME YOK. Program zaten derlenmis
# (client.dist/) geliyor -> internet/gcc/Cython gerekmez, zayif islemcide dakikalarca
# beklenmez (sahanin en kirilgan adimi kalkti). Kod da .bin icinde okunamaz (§9.4).
#
# Sertlestirmeler KORUNDU: dar sudoers (yalniz fatih-uninstall), xorg tty kilidi
# (DontVTSwitch/DontZap), ogretmen/ogrenci passwd -l, config 600, lightdm autologin.
#
# Calistirma:  sudo bash setup_pardus.sh
# ----------------------------------------------------------------------------
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Lütfen sudo ile çalıştırın: sudo bash $0"
  exit 1
fi

BETIK_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BETIK_DIR"
INSTALL_DIR="/opt/fatih-client"
DIST_DIR="app"   # client.dist bu isimle paketlenir

echo "========================================================="
echo " MEBRE Akıllı Tahta (Pardus) kurulumu başlıyor..."
echo "========================================================="

# --- [0/6] Ön kontroller ---
echo "[0/6] Ön kontroller..."
# GUI dosya yoneticisiyle zip acilinca Linux'ta CALISTIRMA izni (+x) sik kaybolur ->
# client.bin orada olur ama -x DUSER, setup 'yok' sanirdi (saha 17 Ağu). Once +x geri ver,
# SONRA VARLIGA (-f) bak. Kurulu kopyaya zaten [2/6]'da chmod +x uygulaniyor.
chmod +x "$DIST_DIR/client.bin" 2>/dev/null || true
if [ ! -f "$DIST_DIR/client.bin" ]; then
    echo "❌ KURULUM DURDURULDU: $DIST_DIR/client.bin yok. Zip'i app/ klasörüyle birlikte tam kopyalayın."
    exit 1
fi
_BOS_MB=$(df -Pm /opt 2>/dev/null | awk 'NR==2{print $4}')
if [ -n "$_BOS_MB" ] && [ "$_BOS_MB" -lt 500 ]; then
    echo "❌ KURULUM DURDURULDU: /opt bölümünde yalnızca ${_BOS_MB} MB boş (en az 500 MB gerekli)."
    exit 1
fi
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then :; else
    echo "  ⚠ İnternet yok. Kurulum devam eder ama tahta TANITIMI için internet gerekli."
fi

# --- Kurum kodu (en başta — yanlış girişte iş boşa gitmesin) ---
echo ""
_ONCEKI_KK=""
EXISTING_CONFIG="/home/etapadmin/.config/fatih-client/config.ini"
[ -f "$EXISTING_CONFIG" ] && _ONCEKI_KK=$(sed -nr 's/^corporate_code\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG")
read -r -p "Kurum Kodu [${_ONCEKI_KK:-yok}]: " CORPORATE_CODE </dev/tty
[ -z "$CORPORATE_CODE" ] && CORPORATE_CODE="$_ONCEKI_KK"

# --- Kurulum kodu: Readme.txt'ten 12 haneli rakam kodu OTOMATIK oku (§9.3) ---
# Teknisyen elle yazmaz; Readme.txt'e panelden gelen kod konur (ya da GUI'de girilir).
KURULUM_KODU=""
for _rf in "Readme.txt" "readme.txt" "secret.txt"; do
    [ -f "$_rf" ] || continue
    KURULUM_KODU=$(grep -oE '[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}' "$_rf" | head -1 | tr -cd '0-9')
    [ -n "$KURULUM_KODU" ] && break
done

# --- [1/6] Bağımlılıklar (SADECE çalışma-anı; DERLEME aracı YOK) ---
echo "[1/6] Çalışma-anı bağımlılıkları kontrol ediliyor..."
# Nuitka standalone Qt/evdev/pyudev'i yanında getirir; yine de sistem Qt eklentileri
# ve xdotool/pactl gibi araçlar kilit için lazım olabilir. Varsa kurar, yoksa atlar.
apt-get install -y --no-install-recommends libxcb-xinerama0 x11-xserver-utils 2>/dev/null || \
    echo "  ⚠ Bazı sistem paketleri kurulamadı (internet yok olabilir) — çoğu zaman sorun olmaz."

# MEB KÖK SERTİFİKASI (FATİH ağı SSL denetimi) — TÜBİTAK BİLGEM YTE kılavuzu (11.12.2024).
# FATİH/MEB okul ağı HTTPS'i kendi MEB sertifikasıyla açıp inceliyor (SSL inspection).
# eba-certs paketi MEB kök CA'sını /etc/ssl/certs/ca-certificates.crt'ye ekler -> istemci
# (REQUESTS_CA_BUNDLE ile sistem demetini kullanir, asagida) apiv5.mebre.com.tr'ye baglanir.
# Pardus ETAP/Egitim'de zaten kuruludur; duz Pardus'ta biz kuruyoruz. Best-effort (internet lazim).
apt-get install -y eba-certs 2>/dev/null && echo "  ✓ MEB sertifikasi (eba-certs) kuruldu." || \
    echo "  ⚠ eba-certs kurulamadi (internet yok ya da depo erisimi). FATİH aginda enroll takilirsa: sudo apt install eba-certs"
update-ca-certificates 2>/dev/null || true

# --- [2/6] Program dosyaları ---
echo "[2/6] Program dosyaları kopyalanıyor..."
pkill -9 -f 'client.bin' 2>/dev/null || true
pkill -9 -f 'main.py'    2>/dev/null || true
pkill -9 -f 'client.py'  2>/dev/null || true
# Eski Cython kurulumundan kalan düz kod / .so'ları temizle (öncelik karışmasın).
rm -f "$INSTALL_DIR/client.py" "$INSTALL_DIR/main.py" "$INSTALL_DIR"/client*.so 2>/dev/null || true
mkdir -p "$INSTALL_DIR"
cp -r "$DIST_DIR/." "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/client.bin"
[ -f "$INSTALL_DIR/version.txt" ] && _PKG_VERSION=$(tr -d ' \t\n\r' < "$INSTALL_DIR/version.txt")
[ -z "$_PKG_VERSION" ] && _PKG_VERSION="V6.00.00"
echo "  → Kurulan sürüm: $_PKG_VERSION"

# --- [3/6] Yapılandırma (eski değerleri koru: token/şifre) ---
echo "[3/6] Yapılandırma yazılıyor..."
BOARD_ID="0"; BOARD_NAME="Pardus Board"; ADMIN_PASSWORD="803580"; PASSWORD_CHANGED="false"; DEVICE_TOKEN=""
if [ -f "$EXISTING_CONFIG" ]; then
    BOARD_ID=$(sed -nr 's/^board_id\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG"); [ -z "$BOARD_ID" ] && BOARD_ID="0"
    BOARD_NAME=$(sed -nr 's/^board_name\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG"); [ -z "$BOARD_NAME" ] && BOARD_NAME="Pardus Board"
    ADMIN_PASSWORD=$(sed -nr 's/^admin_password\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG"); [ -z "$ADMIN_PASSWORD" ] && ADMIN_PASSWORD="803580"
    PASSWORD_CHANGED=$(sed -nr 's/^password_changed\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG"); [ -z "$PASSWORD_CHANGED" ] && PASSWORD_CHANGED="false"
    # Zaten tanıtılmışsa kimliği KORU (silinirse tahta tekrar tanıtılmalı).
    DEVICE_TOKEN=$(sed -nr 's/^device_token\s*=\s*(.*)/\1/p' "$EXISTING_CONFIG")
fi

# Admin şifresi düz metin SAKLANMAZ: PBKDF2'ye çevir (zaten hash'liyse dokunma).
# Pardus'ta python3 sistemde HER ZAMAN var (kurulum aracı değil, standart); .bin'in
# gömülü Python'ı yerine sistem python3'ü kullanılır (eski setup.sh ile aynı yöntem).
case "$ADMIN_PASSWORD" in
    PBKDF2:*) : ;;
    *)
        _H=$(python3 -c "
import hashlib, os, sys
p = sys.argv[1] if len(sys.argv) > 1 else '803580'
t = os.urandom(16)
print('PBKDF2:%s:%s' % (t.hex(), hashlib.pbkdf2_hmac('sha256', p.encode(), t, 200000).hex()))
" "$ADMIN_PASSWORD" 2>/dev/null || true)
        [ -n "$_H" ] && ADMIN_PASSWORD="$_H"
        _H=""
        ;;
esac

# Kurulum kodu ENC2 değil ENC yazılır; istemci ilk açılışta ENC2'ye terfi eder (§9.3).
KURULUM_KODU_ENC=""
[ -n "$KURULUM_KODU" ] && KURULUM_KODU_ENC="ENC:$(printf '%s' "$KURULUM_KODU" | base64 -w0)"
KURULUM_KODU=""

cat > "$INSTALL_DIR/config.ini" <<EOF
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
[ -n "$DEVICE_TOKEN" ] && echo "device_token = $DEVICE_TOKEN" >> "$INSTALL_DIR/config.ini"
[ -n "$KURULUM_KODU_ENC" ] && echo "kurulum_kodu = $KURULUM_KODU_ENC" >> "$INSTALL_DIR/config.ini"

mkdir -p /home/etapadmin/.config/fatih-client
cp "$INSTALL_DIR/config.ini" /home/etapadmin/.config/fatih-client/config.ini
chown -R etapadmin:etapadmin /home/etapadmin/.config/fatih-client
chmod 600 /home/etapadmin/.config/fatih-client/config.ini
chmod 600 "$INSTALL_DIR/config.ini"

# --- [4/6] Servis + autostart (.bin çalıştırır; Python YOK) ---
echo "[4/6] Servis ve otomatik başlatma..."
cat > /etc/systemd/system/fatih-client-app.service <<EOF
[Unit]
Description=Mebre Akıllı Tahta İstemcisi
After=graphical-session.target
Wants=network-online.target
[Service]
Type=simple
User=etapadmin
Environment=DISPLAY=:0
# MEB CA'yi (eba-certs) gormesi icin istemci SISTEM CA demetini kullanir; yoksa gomulu
# certifi'yi kullanip FATİH SSL denetimine takilirdi. requests, verify=True olsa da bu
# env'i dinler (dogrulandi). Sistem demeti standart CA'lari da icerir -> ev interneti de calisir.
Environment=REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/client.bin
Restart=always
RestartSec=3
[Install]
WantedBy=graphical-session.target
EOF
systemctl daemon-reload
systemctl enable fatih-client-app.service 2>/dev/null || true

mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/fatih-client-autostart.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Mebre Akıllı Tahta
Comment=Akıllı Tahta Kilit Sistemi
Exec=$INSTALL_DIR/client.bin
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=false
EOF
chmod 644 /etc/xdg/autostart/fatih-client-autostart.desktop

# --- [5/6] Uzaktan kaldırma yetkisi + tty/zap kilidi (sertleştirme korundu) ---
echo "[5/6] Güvenlik sertleştirmeleri..."
# Uzaktan KALDIRMA + uzaktan GUNCELLEME icin dar yetkiler (ikisi de argumansiz).
_SUDO_SATIR=""
if [ -f "$BETIK_DIR/uninstall.sh" ]; then
    cp "$BETIK_DIR/uninstall.sh" /usr/local/bin/fatih-uninstall
    chown root:root /usr/local/bin/fatih-uninstall
    chmod 700 /usr/local/bin/fatih-uninstall
    _SUDO_SATIR='etapadmin ALL=(root) NOPASSWD: /usr/local/bin/fatih-uninstall ""'
fi
if [ -f "$BETIK_DIR/fatih-update.sh" ]; then
    cp "$BETIK_DIR/fatih-update.sh" /usr/local/bin/fatih-update
    chown root:root /usr/local/bin/fatih-update
    chmod 700 /usr/local/bin/fatih-update
    # §9.2: uzaktan guncelleme. Argumansiz — staging yolu betikte sabit (disaridan yonlendirilemez).
    _SUDO_SATIR="$_SUDO_SATIR
etapadmin ALL=(root) NOPASSWD: /usr/local/bin/fatih-update"
fi
if [ -n "$_SUDO_SATIR" ]; then
    printf '%s\n' "$_SUDO_SATIR" > /etc/sudoers.d/fatih-client
    chmod 440 /etc/sudoers.d/fatih-client
    chown root:root /etc/sudoers.d/fatih-client
    visudo -c -f /etc/sudoers.d/fatih-client >/dev/null 2>&1 || { rm -f /etc/sudoers.d/fatih-client; echo "  ⚠ sudoers geçersiz, kaldırıldı."; }
fi

mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/10-fatih-lockdown.conf << 'XORG_EOF'
Section "ServerFlags"
    Option "DontVTSwitch" "on"
    Option "DontZap"      "on"
EndSection
XORG_EOF
chmod 644 /etc/X11/xorg.conf.d/10-fatih-lockdown.conf

# İzinler: yalnız root + etapadmin (öğrenci/öğretmen okuyup kopyalayamaz).
chown -R root:etapadmin "$INSTALL_DIR"
chmod -R 750 "$INSTALL_DIR"
chmod 600 "$INSTALL_DIR/config.ini"

# --- [6/6] Kullanıcı hesapları + otomatik giriş ---
echo "[6/6] Kullanıcı hesapları ve otomatik giriş..."
id "etapadmin" &>/dev/null && passwd -d etapadmin 2>/dev/null || true
id "ogretmen"  &>/dev/null && passwd -l ogretmen  2>/dev/null || true
id "ogrenci"   &>/dev/null && passwd -l ogrenci   2>/dev/null || true

LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
if [ -f "$LIGHTDM_CONF" ] || [ -d "/etc/lightdm" ]; then
    if grep -q "autologin-user" "$LIGHTDM_CONF" 2>/dev/null; then
        sed -i 's/^#*autologin-user=.*/autologin-user=etapadmin/' "$LIGHTDM_CONF"
    elif grep -q "\[Seat:\*\]" "$LIGHTDM_CONF" 2>/dev/null; then
        sed -i '/\[Seat:\*\]/a autologin-user=etapadmin' "$LIGHTDM_CONF"
    else
        mkdir -p /etc/lightdm
        printf '\n[Seat:*]\nautologin-user=etapadmin\n' >> "$LIGHTDM_CONF"
    fi
fi
sudo -u etapadmin dbus-launch gsettings set org.cinnamon.desktop.screensaver lock-enabled false 2>/dev/null || true
sudo -u etapadmin dbus-launch gsettings set org.cinnamon.desktop.screensaver idle-activation-enabled false 2>/dev/null || true

echo "========================================================="
echo "✅ KURULUM TAMAMLANDI  (sürüm $_PKG_VERSION)"
echo "Kurum kodu : ${CORPORATE_CODE:-(girilmedi)}"
if [ -n "$DEVICE_TOKEN" ]; then
    echo "Tahta      : ✅ Zaten tanıtılmış (kimlik korundu)"
elif [ -n "$KURULUM_KODU_ENC" ]; then
    echo "Tahta      : ⏳ Kurulum kodu gömüldü — yeniden başlatınca ekrandan tanıtın."
else
    echo "Tahta      : ⚠ Kurulum kodu yok — tanıtım ekranında 12 haneli kodu elle girin."
fi
echo "Yeniden başlatma önerilir:  sudo reboot"
echo "========================================================="

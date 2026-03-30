#!/bin/bash

# =============================================================
# Fatih Client - Birleştirilmiş Kurulum Scripti
# Login ekranı ÖNCESİ kilitleme için tam kurulum
# Pardus 19 (LightDM) ve diğer sistemler (GDM3) ile uyumlu
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script'in bulunduğu dizin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/opt/fatih-client"
VENV_DIR="$APP_DIR/venv"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         FATİH CLIENT - TAM KURULUM                       ║"
echo "║     (Pre-Login Kilitleme Dahil)                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}HATA: Root yetkisi gerekli (sudo)${NC}"
    exit 1
fi

# Display manager tespit et
detect_display_manager() {
    # Önce config dosyalarına bak (daha güvenilir)
    if [ -f "/etc/lightdm/lightdm.conf" ]; then
        echo "lightdm"
    elif [ -d "/etc/gdm3" ]; then
        echo "gdm3"
    elif [ -d "/etc/gdm" ]; then
        echo "gdm"
    # Sonra aktif servislere bak
    elif systemctl is-active --quiet lightdm 2>/dev/null; then
        echo "lightdm"
    elif systemctl is-active --quiet gdm3 2>/dev/null; then
        echo "gdm3"
    elif systemctl is-active --quiet gdm 2>/dev/null; then
        echo "gdm"
    else
        echo "unknown"
    fi
}

DM=$(detect_display_manager)
echo -e "Tespit edilen Display Manager: ${GREEN}$DM${NC}"
echo ""

echo "Bu kurulum şunları yapacak:"
echo "  • Fatih Client uygulamasını kurar"
echo "  • fatih-kiosk kullanıcısı oluşturur"
echo "  • Bilgisayar açıldığında login ÖNCESİ kilit ekranı gösterir"
echo "  • USB veya şifre ile açıldıktan sonra normal login ekranı görünür"
echo ""
echo -e "${YELLOW}DİKKAT: Bu işlem sistem başlangıç ayarlarını değiştirecek!${NC}"
echo ""
echo "Devam etmek istiyor musunuz? (e/h)"
read -r response
if [ "$response" != "e" ] && [ "$response" != "E" ]; then
    echo "Kurulum iptal edildi."
    exit 1
fi

# ============================================================
# BÖLÜM 1: UYGULAMA KURULUMU
# ============================================================
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  BÖLÜM 1: UYGULAMA KURULUMU${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

# 1.1 Dizinleri oluştur
echo ""
echo -e "${CYAN}[1.1] Dizinler oluşturuluyor...${NC}"
mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/resources"
mkdir -p "$APP_DIR/logs"
echo -e "  ${GREEN}✓${NC} $APP_DIR oluşturuldu"

# 1.2 Sistem bağımlılıklarını kur
echo ""
echo -e "${CYAN}[1.2] Sistem bağımlılıkları kuruluyor...${NC}"
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv python3-dev gcc libxcb-cursor0 xauth 2>/dev/null
echo -e "  ${GREEN}✓${NC} Sistem bağımlılıkları kuruldu"

# 1.3 Python virtual environment oluştur
echo ""
echo -e "${CYAN}[1.3] Python ortamı hazırlanıyor...${NC}"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements.txt" -q
"$VENV_DIR/bin/pip" install Cython==3.0.11 setuptools -q
echo -e "  ${GREEN}✓${NC} Python ortamı hazır"

# 1.4 Kodu şifrele (Cython ile .so'ya derle)
echo ""
echo -e "${CYAN}[1.4] Kod şifreleniyor (Cython Compilation)...${NC}"
cd "$SCRIPT_DIR"
# Eski derlemeleri temizle
rm -f client.c client*.so 2>/dev/null
rm -rf build/ 2>/dev/null

# Cython ile derle
"$VENV_DIR/bin/python" -c "
from setuptools import setup
from Cython.Build import cythonize
setup(ext_modules=cythonize(['client.py'], compiler_directives={'language_level': '3'}))
" build_ext --inplace 2>/dev/null

COMPILED_FILE=$(find "$SCRIPT_DIR" -maxdepth 1 -name "client*.so" -print -quit)
if [ -n "$COMPILED_FILE" ]; then
    echo -e "  ${GREEN}✓${NC} Kod başarıyla şifrelendi (.so oluşturuldu)"
    USE_COMPILED=true
else
    echo -e "  ${YELLOW}⚠${NC} Cython derleme başarısız, düz Python kullanılacak"
    USE_COMPILED=false
fi

# 1.5 Uygulama dosyalarını kopyala
echo ""
echo -e "${CYAN}[1.5] Uygulama dosyaları kopyalanıyor...${NC}"

if [ "$USE_COMPILED" = true ]; then
    # Derlenmiş .so dosyasını kopyala
    cp "$COMPILED_FILE" "$APP_DIR/"
    
    # fatih.py oluştur (derlenmiş modülü import eder)
    cat <<MAIN_EOF > "$APP_DIR/fatih.py"
import os, sys
os.chdir("/opt/fatih-client")
import client
if hasattr(client, 'main'):
    client.main()
MAIN_EOF
    echo -e "  ${GREEN}✓${NC} Şifrelenmiş kod kopyalandı (.so)"
else
    # Düz Python dosyasını kopyala (fallback)
    cp "$SCRIPT_DIR/client.py" "$APP_DIR/fatih.py"
fi

cp "$SCRIPT_DIR/config.ini" "$APP_DIR/"
cp "$SCRIPT_DIR/launch.sh" "$APP_DIR/" 2>/dev/null || true
chmod +x "$APP_DIR/launch.sh" 2>/dev/null || true
cp -r "$SCRIPT_DIR/resources"/* "$APP_DIR/resources/" 2>/dev/null || true
cp "$SCRIPT_DIR/../../fatih-manager.sh" "$APP_DIR/" 2>/dev/null || true
chmod +x "$APP_DIR/fatih-manager.sh" 2>/dev/null || true

# Kaynak kodu temizle (güvenlik)
rm -f "$APP_DIR/client.py" 2>/dev/null
rm -f "$SCRIPT_DIR/client.c" 2>/dev/null
rm -rf "$SCRIPT_DIR/build/" 2>/dev/null

echo -e "  ${GREEN}✓${NC} Dosyalar kopyalandı"

# ============================================================
# BÖLÜM 2: PRE-LOGIN YAPILANDIRMASI
# ============================================================
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  BÖLÜM 2: PRE-LOGIN YAPILANDIRMASI${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

# 2.1 fatih-kiosk kullanıcısı oluştur
echo ""
echo -e "${CYAN}[2.1] fatih-kiosk kullanıcısı oluşturuluyor...${NC}"

if ! id "fatih-kiosk" &>/dev/null; then
    # Generate password hash directly to bypass PAM token manipulation errors (e.g. complexity rules)
    KIOSK_HASH=$(python3 -c "import crypt; print(crypt.crypt('fatih2025secure', crypt.mksalt(crypt.METHOD_SHA512)))")
    useradd -m -s /bin/bash -G video,audio,input -p "$KIOSK_HASH" fatih-kiosk
    echo -e "  ${GREEN}✓${NC} fatih-kiosk kullanıcısı oluşturuldu"
else
    echo -e "  ${YELLOW}⚠${NC} fatih-kiosk kullanıcısı zaten mevcut"
    # Gruplarını güncelle
    usermod -a -G video,audio,input fatih-kiosk 2>/dev/null || true
fi

# 2.2 Display Manager yapılandır
echo ""
echo -e "${CYAN}[2.2] Display Manager yapılandırılıyor ($DM)...${NC}"

case $DM in
    lightdm)
        LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
        
        # Backup
        if [ -f "$LIGHTDM_CONF" ] && [ ! -f "${LIGHTDM_CONF}.backup-fatih" ]; then
            cp "$LIGHTDM_CONF" "${LIGHTDM_CONF}.backup-fatih"
            echo -e "  ${GREEN}✓${NC} Backup: ${LIGHTDM_CONF}.backup-fatih"
        fi
        
        # LightDM auto-login yapılandır
        if [ -f "$LIGHTDM_CONF" ]; then
            sed -i '/^autologin-user=/d' "$LIGHTDM_CONF"
            sed -i '/^autologin-user-timeout=/d' "$LIGHTDM_CONF"
            
            if grep -q "^\[Seat:\*\]" "$LIGHTDM_CONF"; then
                sed -i '/^\[Seat:\*\]/a autologin-user=fatih-kiosk\nautologin-user-timeout=0' "$LIGHTDM_CONF"
            else
                echo "" >> "$LIGHTDM_CONF"
                echo "[Seat:*]" >> "$LIGHTDM_CONF"
                echo "autologin-user=fatih-kiosk" >> "$LIGHTDM_CONF"
                echo "autologin-user-timeout=0" >> "$LIGHTDM_CONF"
            fi
        else
            cat > "$LIGHTDM_CONF" << 'LIGHTDM_EOF'
[Seat:*]
autologin-user=fatih-kiosk
autologin-user-timeout=0
LIGHTDM_EOF
        fi
        echo -e "  ${GREEN}✓${NC} LightDM auto-login yapılandırıldı"
        DM_SERVICE="lightdm"
        ;;
        
    gdm3|gdm)
        # GDM dizinini ve config dosyasını belirle
        if [ -d "/etc/gdm3" ]; then
            GDM_DIR="/etc/gdm3"
        elif [ -d "/etc/gdm" ]; then
            GDM_DIR="/etc/gdm"
        else
            # Dizin yoksa oluştur
            GDM_DIR="/etc/gdm3"
            mkdir -p "$GDM_DIR"
        fi
        
        # custom.conf yapılandır
        GDM_CONF="$GDM_DIR/custom.conf"
        
        if [ -f "$GDM_CONF" ] && [ ! -f "${GDM_CONF}.backup-fatih" ]; then
            cp "$GDM_CONF" "${GDM_CONF}.backup-fatih"
            echo -e "  ${GREEN}✓${NC} Backup: ${GDM_CONF}.backup-fatih"
        fi
        
        cat > "$GDM_CONF" << 'GDM_EOF'
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = fatih-kiosk
WaylandEnable=false

[security]
[xdmcp]
[chooser]
[debug]
GDM_EOF
        echo -e "  ${GREEN}✓${NC} GDM custom.conf yapılandırıldı (Wayland devre dışı)"
        
        # ÖNEMLİ: daemon.conf da varsa onu da güncelle (override edebilir)
        GDM_DAEMON_CONF="$GDM_DIR/daemon.conf"
        if [ -f "$GDM_DAEMON_CONF" ]; then
            if [ ! -f "${GDM_DAEMON_CONF}.backup-fatih" ]; then
                cp "$GDM_DAEMON_CONF" "${GDM_DAEMON_CONF}.backup-fatih"
                echo -e "  ${GREEN}✓${NC} Backup: ${GDM_DAEMON_CONF}.backup-fatih"
            fi
            # daemon.conf içindeki auto-login ayarlarını fatih-kiosk için güncelle
            sed -i 's/^AutomaticLogin = .*/AutomaticLogin = fatih-kiosk/g' "$GDM_DAEMON_CONF"
            sed -i 's/^AutomaticLoginEnable = .*/AutomaticLoginEnable = true/g' "$GDM_DAEMON_CONF"
            # Wayland devre dışı bırak (PyQt5/xcb için X11 gerekli)
            sed -i 's/^#WaylandEnable=false/WaylandEnable=false/g' "$GDM_DAEMON_CONF"
            if ! grep -q "^WaylandEnable" "$GDM_DAEMON_CONF"; then
                sed -i '/^\[daemon\]/a WaylandEnable=false' "$GDM_DAEMON_CONF"
            fi
            # Eğer satırlar yoksa ekle
            if ! grep -q "^AutomaticLoginEnable" "$GDM_DAEMON_CONF"; then
                sed -i '/^\[daemon\]/a AutomaticLoginEnable = true' "$GDM_DAEMON_CONF"
            fi
            if ! grep -q "^AutomaticLogin = fatih-kiosk" "$GDM_DAEMON_CONF"; then
                sed -i '/^AutomaticLoginEnable/a AutomaticLogin = fatih-kiosk' "$GDM_DAEMON_CONF"
            fi
            echo -e "  ${GREEN}✓${NC} GDM daemon.conf da güncellendi"
        fi
        
        DM_SERVICE="$DM"
        ;;
        
    *)
        echo -e "  ${RED}HATA: Bilinmeyen Display Manager ($DM)${NC}"
        echo "  Manuel yapılandırma gerekli."
        exit 1
        ;;
esac

# 2.3 Kiosk autostart ayarla
echo ""
echo -e "${CYAN}[2.3] Kiosk autostart ayarlanıyor...${NC}"

KIOSK_HOME="/home/fatih-kiosk"
KIOSK_AUTOSTART="$KIOSK_HOME/.config/autostart"
mkdir -p "$KIOSK_AUTOSTART"

cat > "$KIOSK_AUTOSTART/fatih-kiosk.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=Fatih Kiosk Lock
Comment=Pre-login lock screen
Exec=/opt/fatih-client/kiosk-launcher.sh
X-GNOME-Autostart-enabled=true
X-MATE-Autostart-enabled=true
Hidden=false
NoDisplay=false
DESKTOP_EOF

chown -R fatih-kiosk:fatih-kiosk "$KIOSK_HOME/.config"
echo -e "  ${GREEN}✓${NC} Autostart yapılandırıldı"

# 2.4 Kiosk launcher ve helper scriptleri kopyala
echo ""
echo -e "${CYAN}[2.4] Kiosk launcher ve helper scriptler kopyalanıyor...${NC}"

cp "$SCRIPT_DIR/kiosk-launcher.sh" "$APP_DIR/kiosk-launcher.sh"
chmod +x "$APP_DIR/kiosk-launcher.sh"
echo -e "  ${GREEN}✓${NC} Kiosk launcher kopyalandı"

cp "$SCRIPT_DIR/autologin-switch.sh" "$APP_DIR/autologin-switch.sh"
chmod +x "$APP_DIR/autologin-switch.sh"
echo -e "  ${GREEN}✓${NC} Auto-login switch helper kopyalandı"

# 2.5 Systemd servisi: boot'ta AutomaticLogin=fatih-kiosk'a sıfırla
echo ""
echo -e "${CYAN}[2.5] Boot reset servisi kuruluyor...${NC}"

cp "$SCRIPT_DIR/fatih-kiosk-reset.service" /etc/systemd/system/fatih-kiosk-reset.service
systemctl daemon-reload
systemctl enable fatih-kiosk-reset.service
echo -e "  ${GREEN}✓${NC} fatih-kiosk-reset.service kuruldu ve etkinleştirildi"

# 2.6 Normal mod autostart (tüm kullanıcılar için, fatih-kiosk hariç)
echo ""
echo -e "${CYAN}[2.6] Normal mod autostart ayarlanıyor...${NC}"

# Sistem geneli autostart (ogretmen, ogrenci, etapadmin vs. için)
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/fatih-client-autostart.desktop << 'AUTOSTART_EOF'
[Desktop Entry]
Type=Application
Name=Fatih Client
Comment=Fatih Projesi Smartboard Client
Path=/opt/fatih-client/
Exec=sh -c 'sleep 5 && /opt/fatih-client/launch.sh'
Terminal=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=5
AUTOSTART_EOF
echo -e "  ${GREEN}✓${NC} Sistem geneli autostart yapılandırıldı"

# 2.7 Sudo izinleri (shutdown/reboot, display manager, autologin-switch)
echo ""
echo -e "${CYAN}[2.7] Sudo izinleri yapılandırılıyor...${NC}"

cat > /etc/sudoers.d/fatih-client << 'SUDOERS_EOF'
# Fatih Client - Sistem komutları için sudo izinleri
# Display manager restart
fatih-kiosk ALL=(ALL) NOPASSWD: /bin/systemctl restart lightdm
fatih-kiosk ALL=(ALL) NOPASSWD: /bin/systemctl restart gdm3
fatih-kiosk ALL=(ALL) NOPASSWD: /bin/systemctl restart gdm

# Auto-login switch (kiosk -> ogretmen ve geri)
fatih-kiosk ALL=(ALL) NOPASSWD: /opt/fatih-client/autologin-switch.sh

# Shutdown ve reboot komutları (tüm kullanıcılar için)
ALL ALL=(ALL) NOPASSWD: /sbin/poweroff
ALL ALL=(ALL) NOPASSWD: /sbin/reboot
ALL ALL=(ALL) NOPASSWD: /sbin/shutdown
ALL ALL=(ALL) NOPASSWD: /usr/sbin/poweroff
ALL ALL=(ALL) NOPASSWD: /usr/sbin/reboot
ALL ALL=(ALL) NOPASSWD: /usr/sbin/shutdown
SUDOERS_EOF

chmod 0440 /etc/sudoers.d/fatih-client

# Eski dosyayı sil (varsa)
rm -f /etc/sudoers.d/fatih-kiosk 2>/dev/null || true

echo -e "  ${GREEN}✓${NC} Sudo izinleri yapılandırıldı"

# 2.8 Dosya sahipliği
echo ""
echo -e "${CYAN}[2.8] Dosya izinleri ayarlanıyor...${NC}"
chown -R fatih-kiosk:fatih-kiosk "$APP_DIR"
echo -e "  ${GREEN}✓${NC} İzinler ayarlandı"

# ============================================================
# ÖZET
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              KURULUM TAMAMLANDI                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Sistem şimdi şu şekilde çalışacak:"
echo "  1. Bilgisayar açılır (fatih-kiosk-reset.service → AutomaticLogin=fatih-kiosk)"
echo "  2. fatih-kiosk otomatik giriş yapar"
echo "  3. Fatih kilit ekranı gösterilir"
echo "  4. USB, şifre veya mobil uygulama ile kilit açılır"
echo "  5. AutomaticLogin=ogretmen'e çevrilir, GDM restart"
echo "  6. ogretmen otomatik giriş yapar, client.py normal mod başlar"
echo "  7. Mobil uygulamadan kilitleme/açma çalışır"
echo ""
echo -e "${YELLOW}ÖNEMLİ:${NC} Değişikliklerin aktif olması için bilgisayarı"
echo "        yeniden başlatmanız gerekiyor."
echo ""
echo -e "${CYAN}Test için:${NC} sudo reboot"
echo ""
echo -e "${CYAN}Devre dışı bırakmak için:${NC}"
if [ "$DM" = "lightdm" ]; then
    echo "  sudo nano /etc/lightdm/lightdm.conf"
    echo "  'autologin-user=fatih-kiosk' satırını silin"
else
    echo "  sudo nano /etc/gdm3/custom.conf"
    echo "  'AutomaticLoginEnable = true' -> 'false' yapın"
fi
echo ""

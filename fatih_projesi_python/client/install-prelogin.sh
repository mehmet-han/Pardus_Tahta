#!/bin/bash

# =============================================================
# Fatih Client Pre-Login Installation Script
# Login ekranı ÖNCESİ kilitleme için kurulum
# Pardus 19 (LightDM) ve diğer sistemler (GDM3) ile uyumlu
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║     FATİH CLIENT - PRE-LOGIN KİLİTLEME KURULUMU          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Bu kurulum, kullanıcı login ekranından ÖNCE Fatih kilit"
echo "ekranının gösterilmesini sağlar."
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}HATA: Root yetkisi gerekli (sudo)${NC}"
    exit 1
fi

# Display manager tespit et
detect_display_manager() {
    if systemctl is-active --quiet lightdm 2>/dev/null; then
        echo "lightdm"
    elif systemctl is-active --quiet gdm3 2>/dev/null; then
        echo "gdm3"
    elif systemctl is-active --quiet gdm 2>/dev/null; then
        echo "gdm"
    elif [ -f "/etc/lightdm/lightdm.conf" ]; then
        echo "lightdm"
    elif [ -f "/etc/gdm3/custom.conf" ]; then
        echo "gdm3"
    else
        echo "unknown"
    fi
}

DM=$(detect_display_manager)
echo -e "Tespit edilen Display Manager: ${GREEN}$DM${NC}"
echo ""

# Onay iste
echo -e "${YELLOW}DİKKAT: Bu işlem sistem başlangıç ayarlarını değiştirecek!${NC}"
echo "Devam etmek istiyor musunuz? (e/h)"
read -r response
if [ "$response" != "e" ] && [ "$response" != "E" ]; then
    echo "Kurulum iptal edildi."
    exit 0
fi

# ============================================================
# 1. fatih-kiosk kullanıcısı oluştur
# ============================================================
echo ""
echo -e "${CYAN}[1/6] fatih-kiosk kullanıcısı oluşturuluyor...${NC}"

if ! id "fatih-kiosk" &>/dev/null; then
    useradd -m -s /bin/bash -G video,audio,input fatih-kiosk
    echo "fatih-kiosk:fatih2025secure" | chpasswd
    echo -e "  ${GREEN}✓${NC} fatih-kiosk kullanıcısı oluşturuldu"
    echo -e "  ${YELLOW}Şifre: fatih2025secure${NC}"
else
    echo -e "  ${YELLOW}fatih-kiosk kullanıcısı zaten mevcut${NC}"
fi

# ============================================================
# 2. Display Manager'ı yapılandır
# ============================================================
echo ""
echo -e "${CYAN}[2/6] Display Manager yapılandırılıyor ($DM)...${NC}"

case $DM in
    lightdm)
        # LightDM yapılandırması (Pardus 19)
        LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
        
        # Backup
        if [ -f "$LIGHTDM_CONF" ] && [ ! -f "${LIGHTDM_CONF}.backup-fatih" ]; then
            cp "$LIGHTDM_CONF" "${LIGHTDM_CONF}.backup-fatih"
            echo -e "  ${GREEN}✓${NC} Backup oluşturuldu: ${LIGHTDM_CONF}.backup-fatih"
        fi
        
        # LightDM auto-login yapılandır
        if [ -f "$LIGHTDM_CONF" ]; then
            # Mevcut autologin ayarlarını kaldır
            sed -i '/^autologin-user=/d' "$LIGHTDM_CONF"
            sed -i '/^autologin-user-timeout=/d' "$LIGHTDM_CONF"
            
            # [Seat:*] bölümüne ekle
            if grep -q "^\[Seat:\*\]" "$LIGHTDM_CONF"; then
                sed -i '/^\[Seat:\*\]/a autologin-user=fatih-kiosk\nautologin-user-timeout=0' "$LIGHTDM_CONF"
            else
                echo "" >> "$LIGHTDM_CONF"
                echo "[Seat:*]" >> "$LIGHTDM_CONF"
                echo "autologin-user=fatih-kiosk" >> "$LIGHTDM_CONF"
                echo "autologin-user-timeout=0" >> "$LIGHTDM_CONF"
            fi
        else
            # Dosya yoksa oluştur
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
        # GDM3 yapılandırması
        GDM_CONF="/etc/gdm3/custom.conf"
        if [ ! -f "$GDM_CONF" ]; then
            GDM_CONF="/etc/gdm/custom.conf"
        fi
        
        # Backup
        if [ -f "$GDM_CONF" ] && [ ! -f "${GDM_CONF}.backup-fatih" ]; then
            cp "$GDM_CONF" "${GDM_CONF}.backup-fatih"
            echo -e "  ${GREEN}✓${NC} Backup oluşturuldu: ${GDM_CONF}.backup-fatih"
        fi
        
        cat > "$GDM_CONF" << 'GDM_EOF'
# GDM configuration - Modified by Fatih Client
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = fatih-kiosk

[security]

[xdmcp]

[chooser]

[debug]
GDM_EOF
        echo -e "  ${GREEN}✓${NC} GDM3 auto-login yapılandırıldı"
        DM_SERVICE="$DM"
        ;;
        
    *)
        echo -e "  ${RED}HATA: Bilinmeyen Display Manager${NC}"
        echo "  Manuel yapılandırma gerekli."
        exit 1
        ;;
esac

# ============================================================
# 3. Kiosk oturumu için autostart ayarla
# ============================================================
echo ""
echo -e "${CYAN}[3/6] Kiosk oturumu yapılandırılıyor...${NC}"

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
X-KDE-autostart-after=panel
Hidden=false
NoDisplay=false
DESKTOP_EOF

chown -R fatih-kiosk:fatih-kiosk "$KIOSK_HOME/.config"
echo -e "  ${GREEN}✓${NC} Autostart yapılandırıldı"

# ============================================================
# 4. Kiosk launcher scripti oluştur
# ============================================================
echo ""
echo -e "${CYAN}[4/6] Kiosk launcher scripti oluşturuluyor...${NC}"

cat > /opt/fatih-client/kiosk-launcher.sh << 'LAUNCHER_EOF'
#!/bin/bash

# =============================================================
# Fatih Kiosk Mode Launcher
# Pre-login modunda çalışır, kilit açılınca normal login'e geçer
# =============================================================

APP_DIR="/opt/fatih-client"
LOG_DIR="$APP_DIR/logs"
VENV_PYTHON="$APP_DIR/venv/bin/python"

mkdir -p "$LOG_DIR"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_DIR/kiosk.log"
}

log_msg "=== Kiosk mode starting ==="

# Masaüstü bileşenlerini devre dışı bırak (varsa)
for proc in nautilus gnome-shell mate-panel xfce4-panel; do
    killall -q "$proc" 2>/dev/null || true
done

# Siyah arka plan
xsetroot -solid black 2>/dev/null || true

# Ekran koruyucuyu devre dışı bırak
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# X hazır olana kadar bekle
sleep 2

# Qt ortam değişkenleri
QT_SITE_PACKAGES=$(find "$APP_DIR/venv/lib/" -type d -name "site-packages" | head -n 1)
if [ -n "$QT_SITE_PACKAGES" ]; then
    # PyQt5 için
    if [ -d "$QT_SITE_PACKAGES/PyQt5" ]; then
        QT_BASE_PATH="$QT_SITE_PACKAGES/PyQt5/Qt5"
    else
        QT_BASE_PATH="$QT_SITE_PACKAGES/PyQt6/Qt6"
    fi
    
    if [ -d "$QT_BASE_PATH" ]; then
        export QT_PLUGIN_PATH="${QT_BASE_PATH}/plugins"
        export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${QT_BASE_PATH}/lib:${LD_LIBRARY_PATH}"
    fi
fi
export QT_QPA_PLATFORM="xcb"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

log_msg "Starting Fatih Client in kiosk mode..."
log_msg "QT_PLUGIN_PATH=$QT_PLUGIN_PATH"

cd "$APP_DIR" || exit 1

# Fatih Client'ı kiosk modunda başlat
# --kiosk flag'i ile çalıştırılınca, unlock sonrası çıkış yapacak
"$VENV_PYTHON" "$APP_DIR/client.py" --kiosk >> "$LOG_DIR/kiosk.out.log" 2>> "$LOG_DIR/kiosk.err.log"
EXIT_CODE=$?

log_msg "Fatih Client exited with code: $EXIT_CODE"

# Client çıktıktan sonra (kilit açıldıktan sonra) Display Manager'ı yeniden başlat
# Bu sayede normal login ekranı gösterilecek
if [ $EXIT_CODE -eq 0 ]; then
    log_msg "Unlock successful, restarting display manager for user login..."
    
    # Hangi DM çalışıyor?
    if systemctl is-active --quiet lightdm; then
        sudo systemctl restart lightdm
    elif systemctl is-active --quiet gdm3; then
        sudo systemctl restart gdm3
    elif systemctl is-active --quiet gdm; then
        sudo systemctl restart gdm
    fi
else
    log_msg "Client crashed, restarting in 5 seconds..."
    sleep 5
    exec "$0"
fi
LAUNCHER_EOF

chmod +x /opt/fatih-client/kiosk-launcher.sh
echo -e "  ${GREEN}✓${NC} Kiosk launcher oluşturuldu"

# ============================================================
# 5. Sudo izinleri (DM yeniden başlatma için)
# ============================================================
echo ""
echo -e "${CYAN}[5/6] Sudo izinleri yapılandırılıyor...${NC}"

cat > /etc/sudoers.d/fatih-kiosk << 'SUDOERS_EOF'
# Fatih kiosk user - display manager restart permissions
fatih-kiosk ALL=(ALL) NOPASSWD: /bin/systemctl restart lightdm
fatih-kiosk ALL=(ALL) NOPASSWD: /bin/systemctl restart gdm3
fatih-kiosk ALL=(ALL) NOPASSWD: /bin/systemctl restart gdm
SUDOERS_EOF

chmod 0440 /etc/sudoers.d/fatih-kiosk
echo -e "  ${GREEN}✓${NC} Sudo izinleri yapılandırıldı"

# ============================================================
# 6. Client.py'ye --kiosk desteği ekle (bilgi)
# ============================================================
echo ""
echo -e "${CYAN}[6/6] Bilgilendirme...${NC}"
echo ""
echo -e "  ${YELLOW}NOT:${NC} client.py dosyasına --kiosk flag desteği eklenmelidir."
echo "  Kiosk modunda, kilit açıldığında program çıkış yapmalıdır."
echo ""

# ============================================================
# Özet
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              KURULUM TAMAMLANDI                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Sistem şimdi şu şekilde çalışacak:"
echo "  1. Bilgisayar açılır"
echo "  2. fatih-kiosk kullanıcısı otomatik giriş yapar"
echo "  3. Fatih kilit ekranı gösterilir"
echo "  4. USB veya şifre ile kilit açılır"
echo "  5. Normal login ekranı gösterilir (3 kullanıcı seçimi)"
echo ""
echo -e "${YELLOW}TEST İÇİN:${NC}"
echo "  sudo reboot"
echo ""
echo -e "${YELLOW}DEVRE DIŞI BIRAKMAK İÇİN:${NC}"
if [ "$DM" = "lightdm" ]; then
    echo "  sudo nano /etc/lightdm/lightdm.conf"
    echo "  'autologin-user=fatih-kiosk' satırını silin veya yorum yapın"
else
    echo "  sudo nano /etc/gdm3/custom.conf"
    echo "  'AutomaticLoginEnable = true' satırını 'false' yapın"
fi
echo ""
echo -e "${YELLOW}BACKUP DOSYALARI:${NC}"
if [ "$DM" = "lightdm" ]; then
    echo "  /etc/lightdm/lightdm.conf.backup-fatih"
else
    echo "  /etc/gdm3/custom.conf.backup-fatih"
fi
echo ""
echo -e "Devam etmek için Enter'a basın..."
read -r

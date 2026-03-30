#!/bin/bash

# =============================================================
# Fatih Projesi - Ana Yönetim Menüsü
# Akıllı tahta kontrol sistemini kurma, kaldırma ve yönetme
# =============================================================

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script'in bulunduğu dizin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$SCRIPT_DIR/fatih_projesi_python/client"
APP_DIR="/opt/fatih-client"

# Root kontrolü
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Bu işlem için root yetkisi gerekli!${NC}"
        echo "Lütfen 'sudo ./fatih-manager.sh' şeklinde çalıştırın."
        exit 1
    fi
}

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║           FATİH PROJESİ - AKILLI TAHTA YÖNETİMİ          ║"
    echo "║                                                          ║"
    echo "║                    Sürüm: 2.14.0                         ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Durum kontrolü
check_status() {
    echo -e "${BLUE}=== Sistem Durumu ===${NC}"
    echo ""
    
    # Kurulum durumu
    if [ -d "$APP_DIR" ]; then
        echo -e "Kurulum: ${GREEN}✓ Kurulu${NC} ($APP_DIR)"
    else
        echo -e "Kurulum: ${RED}✗ Kurulu Değil${NC}"
    fi
    
    # Autostart durumu - Pre-login (fatih-kiosk) ve normal autostart kontrol et
    KIOSK_AUTOSTART="/home/fatih-kiosk/.config/autostart/fatih-kiosk.desktop"
    SYS_AUTOSTART="/etc/xdg/autostart/fatih-client-autostart.desktop"
    ACTUAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo "etapadmin")}
    USER_AUTOSTART="/home/$ACTUAL_USER/.config/autostart/fatih-client-autostart.desktop"
    
    # GDM/LightDM auto-login kontrolü (hem custom.conf hem daemon.conf kontrol et)
    GDM_AUTOLOGIN=$(grep -s 'AutomaticLogin.*fatih-kiosk' /etc/gdm3/custom.conf /etc/gdm3/daemon.conf /etc/gdm/custom.conf /etc/gdm/daemon.conf 2>/dev/null)
    LIGHTDM_AUTOLOGIN=$(grep -s 'autologin-user.*fatih-kiosk' /etc/lightdm/lightdm.conf 2>/dev/null)
    
    # Yanlış kullanıcı için auto-login uyarısı (yorum satırlarını ve dosya ön eklerini hariç tut)
    WRONG_AUTOLOGIN=$(grep -sh 'AutomaticLogin' /etc/gdm3/daemon.conf /etc/gdm/daemon.conf 2>/dev/null | grep -v '^[[:space:]]*#' | grep -v 'fatih-kiosk' | grep -v 'AutomaticLoginEnable')
    
    if [ -n "$GDM_AUTOLOGIN" ] || [ -n "$LIGHTDM_AUTOLOGIN" ]; then
        if [ -n "$WRONG_AUTOLOGIN" ]; then
            echo -e "Pre-Login: ${YELLOW}⚠ Sorunlu${NC} (daemon.conf başka kullanıcı için ayarlı)"
        else
            echo -e "Pre-Login: ${GREEN}✓ Aktif${NC} (fatih-kiosk auto-login)"
        fi
    else
        echo -e "Pre-Login: ${RED}✗ Pasif${NC}"
    fi
    
    if [ -f "$KIOSK_AUTOSTART" ] || [ -f "$SYS_AUTOSTART" ] || [ -f "$USER_AUTOSTART" ]; then
        echo -e "Autostart: ${GREEN}✓ Kurulu${NC}"
    else
        echo -e "Autostart: ${RED}✗ Yok${NC}"
    fi
    
    # Çalışma durumu
    if pgrep -f "fatih.py" > /dev/null; then
        PID=$(pgrep -f "fatih.py")
        echo -e "Program: ${GREEN}✓ Çalışıyor${NC} (PID: $PID)"
    else
        echo -e "Program: ${RED}✗ Çalışmıyor${NC}"
    fi
    
    echo ""
}

# Detaylı durum
show_detailed_status() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              DETAYLI SİSTEM DURUMU                       ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Kurulum durumu
    echo -e "${CYAN}[Kurulum Bilgileri]${NC}"
    if [ -d "$APP_DIR" ]; then
        echo -e "  Durum: ${GREEN}✓ Kurulu${NC}"
        echo -e "  Dizin: $APP_DIR"
        if [ -f "$APP_DIR/fatih.py" ]; then
            VERSION=$(grep -m1 "Version:" "$APP_DIR/fatih.py" 2>/dev/null | head -1 || echo "Bilinmiyor")
            echo -e "  Dosya: fatih.py mevcut"
        fi
    else
        echo -e "  Durum: ${RED}✗ Kurulu Değil${NC}"
    fi
    echo ""
    
    # Autostart durumu
    echo -e "${CYAN}[Autostart Durumu]${NC}"
    ACTUAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo "etapadmin")}
    USER_AUTOSTART="/home/$ACTUAL_USER/.config/autostart/fatih-client-autostart.desktop"
    SYS_AUTOSTART="/etc/xdg/autostart/fatih-client-autostart.desktop"
    
    if [ -f "$SYS_AUTOSTART" ]; then
        echo -e "  Durum: ${GREEN}✓ Aktif (sistem)${NC}"
        echo -e "  Dosya: $SYS_AUTOSTART"
    elif [ -f "$USER_AUTOSTART" ]; then
        echo -e "  Durum: ${GREEN}✓ Aktif (kullanıcı)${NC}"
        echo -e "  Dosya: $USER_AUTOSTART"
    elif [ -f "$SYS_AUTOSTART.disabled" ] || [ -f "$USER_AUTOSTART.disabled" ]; then
        echo -e "  Durum: ${YELLOW}⚠ Devre Dışı (disabled)${NC}"
    else
        echo -e "  Durum: ${RED}✗ Yapılandırılmamış${NC}"
    fi
    echo ""
    
    # Çalışma durumu
    echo -e "${CYAN}[Program Durumu]${NC}"
    if pgrep -f "fatih.py" > /dev/null; then
        PID=$(pgrep -f "fatih.py")
        echo -e "  Durum: ${GREEN}✓ Çalışıyor${NC}"
        echo -e "  PID: $PID"
        # CPU ve Memory kullanımı
        PS_INFO=$(ps -p "$PID" -o %cpu,%mem,etime --no-headers 2>/dev/null)
        if [ -n "$PS_INFO" ]; then
            echo -e "  Kaynak: $PS_INFO (CPU%, MEM%, Süre)"
        fi
    else
        echo -e "  Durum: ${RED}✗ Çalışmıyor${NC}"
    fi
    echo ""
    
    # Log dosyaları
    echo -e "${CYAN}[Log Dosyaları]${NC}"
    ACTUAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo "root")}
    LOG_FILE="/home/$ACTUAL_USER/fatih_client.log"
    if [ -f "$LOG_FILE" ]; then
        LOG_SIZE=$(du -h "$LOG_FILE" 2>/dev/null | cut -f1)
        LOG_LINES=$(wc -l < "$LOG_FILE" 2>/dev/null)
        echo -e "  Ana Log: $LOG_FILE ($LOG_SIZE, $LOG_LINES satır)"
    else
        echo -e "  Ana Log: ${YELLOW}Bulunamadı${NC}"
    fi
    
    ERR_LOG="$APP_DIR/logs/client.err.log"
    if [ -f "$ERR_LOG" ]; then
        ERR_SIZE=$(du -h "$ERR_LOG" 2>/dev/null | cut -f1)
        ERR_LINES=$(wc -l < "$ERR_LOG" 2>/dev/null)
        echo -e "  Hata Log: $ERR_LOG ($ERR_SIZE, $ERR_LINES satır)"
    fi
    echo ""
    
    # Son log girdisi
    echo -e "${CYAN}[Son Log Girdileri]${NC}"
    if [ -f "$LOG_FILE" ]; then
        echo "  Son 3 satır:"
        tail -3 "$LOG_FILE" | sed 's/^/    /'
    fi
    echo ""
}

# Kurulum (Pre-login dahil)
do_install() {
    echo -e "${BLUE}=== Kurulum Başlatılıyor ===${NC}"
    echo ""
    
    if [ -d "$APP_DIR" ]; then
        echo -e "${YELLOW}Program zaten kurulu. Önce kaldırmak ister misiniz? (e/h)${NC}"
        read -r response
        if [ "$response" = "e" ] || [ "$response" = "E" ]; then
            do_uninstall
        else
            echo "Kurulum iptal edildi."
            return
        fi
    fi
    
    # Birleştirilmiş kurulum scriptini kullan
    if [ -f "$CLIENT_DIR/install-unified.sh" ]; then
        cd "$CLIENT_DIR" || exit
        bash install-unified.sh
    elif [ -f "$CLIENT_DIR/install.sh" ]; then
        # Fallback: eski script
        cd "$CLIENT_DIR" || exit
        bash install.sh
        echo ""
        echo -e "${GREEN}Kurulum tamamlandı!${NC}"
        echo -e "${YELLOW}ÖNEMLİ: Değişikliklerin etkili olması için bilgisayarı yeniden başlatın.${NC}"
    else
        echo -e "${RED}Hata: Kurulum scripti bulunamadı: $CLIENT_DIR${NC}"
    fi
}

# Kaldırma
do_uninstall() {
    echo -e "${BLUE}=== Kaldırma Başlatılıyor ===${NC}"
    echo ""
    
    if [ -f "$CLIENT_DIR/uninstall.sh" ]; then
        cd "$CLIENT_DIR" || exit
        bash uninstall.sh
        echo ""
        echo -e "${GREEN}Kaldırma tamamlandı!${NC}"
    else
        echo -e "${RED}Hata: uninstall.sh bulunamadı: $CLIENT_DIR/uninstall.sh${NC}"
    fi
}

# Durdurma
do_stop() {
    echo -e "${BLUE}=== Program Durduruluyor ===${NC}"
    echo ""
    
    if [ -f "$CLIENT_DIR/stop.sh" ]; then
        cd "$CLIENT_DIR" || exit
        bash stop.sh
    else
        # Manuel durdurma
        echo "İşlemler durduruluyor..."
        pkill -9 -f "fatih.py" 2>/dev/null
        pkill -9 -f "fatih-client" 2>/dev/null
        
        # Autostart'ı devre dışı bırak
        if [ -f "/etc/xdg/autostart/fatih-client-autostart.desktop" ]; then
            mv /etc/xdg/autostart/fatih-client-autostart.desktop /etc/xdg/autostart/fatih-client-autostart.desktop.disabled
        fi
        
        echo -e "${GREEN}Program durduruldu!${NC}"
    fi
}

# Başlatma
do_start() {
    echo -e "${BLUE}=== Program Başlatılıyor ===${NC}"
    echo ""
    
    if [ ! -d "$APP_DIR" ]; then
        echo -e "${RED}Program kurulu değil! Önce kurulum yapın.${NC}"
        return
    fi
    
    # Log dizini izinlerini düzelt
    mkdir -p "$APP_DIR/logs"
    chmod 777 "$APP_DIR/logs"
    
    # Zaten çalışıyorsa uyar
    if pgrep -f "fatih.py" > /dev/null; then
        echo -e "${YELLOW}Program zaten çalışıyor. Yeniden başlatmak ister misiniz? (e/h)${NC}"
        read -r response
        if [ "$response" = "e" ] || [ "$response" = "E" ]; then
            pkill -9 -f "fatih.py" 2>/dev/null
            sleep 2
        else
            return
        fi
    fi
    
    # Kullanıcıyı tespit et
    ACTUAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo "etapadmin")}
    USER_ID=$(id -u "$ACTUAL_USER" 2>/dev/null || echo "1000")
    
    # GDM3 sistemi için DISPLAY ve XAUTHORITY ayarları
    USER_DISPLAY=""
    
    # 1. Önce who komutu ile kullanıcının X oturumunu ara (2. sütun :N formatında olanlar)
    USER_DISPLAY=$(who | grep "^$ACTUAL_USER " | awk '{print $2}' | grep -P '^:\d+$' | head -1)
    
    # 2. Kullanıcının X oturumu yoksa, herhangi bir aktif X oturumunu ara (fatih-kiosk dahil)
    if [ -z "$USER_DISPLAY" ]; then
        USER_DISPLAY=$(who | awk '{print $2}' | grep -P '^:\d+$' | head -1)
    fi
    
    # 3. loginctl ile aktif graphical oturumun display'ini bul
    if [ -z "$USER_DISPLAY" ]; then
        for sess in $(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}'); do
            SESS_USER=$(loginctl show-session "$sess" -p Name --value 2>/dev/null)
            SESS_TYPE=$(loginctl show-session "$sess" -p Type --value 2>/dev/null)
            SESS_DISPLAY=$(loginctl show-session "$sess" -p Display --value 2>/dev/null)
            if [ "$SESS_TYPE" = "x11" ] && [ -n "$SESS_DISPLAY" ]; then
                USER_DISPLAY="$SESS_DISPLAY"
                break
            fi
        done
    fi
    
    # 4. /tmp/.X11-unix socket'lerden dene
    if [ -z "$USER_DISPLAY" ]; then
        for d in /tmp/.X11-unix/X*; do
            if [ -S "$d" ]; then
                DNUM=$(basename "$d" | sed 's/X//')
                USER_DISPLAY=":$DNUM"
                break
            fi
        done
    fi
    
    # 5. Son çare: yaygın değerler
    if [ -z "$USER_DISPLAY" ]; then
        USER_DISPLAY=":0"
    fi
    
    # XAUTHORITY yolunu belirle - display sahibinin Xauthority'sini bul
    XAUTH_PATH=""
    
    # Display sahibini bul (who çıktısından :0 sahibi kim?)
    DISPLAY_OWNER=$(who | awk -v disp="$USER_DISPLAY" '$2 == disp {print $1; exit}')
    if [ -n "$DISPLAY_OWNER" ]; then
        DISPLAY_OWNER_ID=$(id -u "$DISPLAY_OWNER" 2>/dev/null)
        if [ -n "$DISPLAY_OWNER_ID" ] && [ -f "/run/user/$DISPLAY_OWNER_ID/gdm/Xauthority" ]; then
            XAUTH_PATH="/run/user/$DISPLAY_OWNER_ID/gdm/Xauthority"
        elif [ -f "/home/$DISPLAY_OWNER/.Xauthority" ]; then
            XAUTH_PATH="/home/$DISPLAY_OWNER/.Xauthority"
        fi
    fi
    
    # Display sahibi bulunamadıysa, mevcut kullanıcının dosyalarını dene
    if [ -z "$XAUTH_PATH" ]; then
        if [ -f "/run/user/$USER_ID/gdm/Xauthority" ]; then
            XAUTH_PATH="/run/user/$USER_ID/gdm/Xauthority"
        elif [ -f "/home/$ACTUAL_USER/.Xauthority" ]; then
            XAUTH_PATH="/home/$ACTUAL_USER/.Xauthority"
        fi
    fi
    
    # Hâlâ bulunamadıysa tüm kullanıcıların Xauthority dosyalarını tara
    if [ -z "$XAUTH_PATH" ]; then
        for xauth in /run/user/*/gdm/Xauthority; do
            if [ -f "$xauth" ]; then
                XAUTH_PATH="$xauth"
                break
            fi
        done
    fi
    
    # Son çare
    if [ -z "$XAUTH_PATH" ]; then
        XAUTH_PATH="/run/user/$USER_ID/gdm/Xauthority"
    fi
    
    echo "Kullanıcı: $ACTUAL_USER"
    echo "DISPLAY: $USER_DISPLAY"
    echo "XAUTHORITY: $XAUTH_PATH"
    [ -n "$DISPLAY_OWNER" ] && [ "$DISPLAY_OWNER" != "$ACTUAL_USER" ] && echo "Display sahibi: $DISPLAY_OWNER"
    echo ""
    
    # X11 izinlerini ver (root olarak çalıştığımız için doğrudan xhost kullanabiliriz)
    DISPLAY="$USER_DISPLAY" XAUTHORITY="$XAUTH_PATH" xhost +local: 2>/dev/null || true
    DISPLAY="$USER_DISPLAY" XAUTHORITY="$XAUTH_PATH" xhost +SI:localuser:$ACTUAL_USER 2>/dev/null || true
    DISPLAY="$USER_DISPLAY" XAUTHORITY="$XAUTH_PATH" xhost +SI:localuser:root 2>/dev/null || true
    
    # Log dosyalarına yazma izni ver
    touch "$APP_DIR/logs/watchdog.log" "$APP_DIR/logs/client.out.log" "$APP_DIR/logs/client.err.log" 2>/dev/null
    chmod 666 "$APP_DIR/logs"/*.log 2>/dev/null
    
    # Programı başlat - GDM3 uyumlu şekilde
    echo "Program başlatılıyor..."
    
    # QT_PLUGIN_PATH'i temizle (sistem Qt'sini kullanmak için)
    unset QT_PLUGIN_PATH
    
    # Direkt venv/bin/python ile başlat (daha güvenilir)
    sudo -u "$ACTUAL_USER" \
        DISPLAY="$USER_DISPLAY" \
        XAUTHORITY="$XAUTH_PATH" \
        QT_QPA_PLATFORM=xcb \
        bash -c "cd $APP_DIR && ./venv/bin/python fatih.py >> $APP_DIR/logs/client.out.log 2>> $APP_DIR/logs/client.err.log &"
    
    sleep 3
    
    if pgrep -f "fatih.py" > /dev/null; then
        PID=$(pgrep -f "fatih.py" | head -1)
        echo -e "${GREEN}Program başarıyla başlatıldı! (PID: $PID)${NC}"
    else
        echo -e "${RED}Program başlatılamadı. Hata logunu kontrol edin:${NC}"
        echo ""
        echo "Son hata mesajları:"
        tail -10 "$APP_DIR/logs/client.err.log" 2>/dev/null || echo "Log dosyası bulunamadı"
        echo ""
        echo "Manuel başlatma için:"
        echo "  export DISPLAY=$USER_DISPLAY"
        echo "  export XAUTHORITY=$XAUTH_PATH"
        echo "  cd $APP_DIR && ./venv/bin/python fatih.py"
    fi
}

# Yeniden başlatma
do_restart() {
    echo -e "${BLUE}=== Program Yeniden Başlatılıyor ===${NC}"
    do_stop
    sleep 2
    do_start
}

# Log görüntüleme
show_logs() {
    echo -e "${BLUE}=== Son Log Kayıtları ===${NC}"
    echo ""
    
    LOG_FILE="/home/$(logname)/fatih_client.log"
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${CYAN}--- Ana Log ($LOG_FILE) ---${NC}"
        tail -30 "$LOG_FILE"
    else
        echo "Ana log dosyası bulunamadı."
    fi
    
    echo ""
    
    ERR_LOG="$APP_DIR/logs/client.err.log"
    if [ -f "$ERR_LOG" ]; then
        echo -e "${CYAN}--- Hata Log ($ERR_LOG) ---${NC}"
        tail -20 "$ERR_LOG"
    fi
    
    echo ""
    echo "Devam etmek için Enter'a basın..."
    read -r
}

# Güncelleme
do_update() {
    echo -e "${BLUE}=== Güncelleme ===${NC}"
    echo ""
    
    # Git pull dene
    echo "Git'ten güncel kodlar çekiliyor..."
    cd "$SCRIPT_DIR" || exit
    
    # Önce HTTPS ile dene
    git remote set-url origin https://github.com/mehmet-han/Pardus_Tahta.git 2>/dev/null
    
    # Git pull (credential olmadan public repo için)
    GIT_TERMINAL_PROMPT=0 git pull origin main 2>/dev/null
    GIT_RESULT=$?
    
    if [ $GIT_RESULT -eq 0 ]; then
        echo -e "${GREEN}Kod güncellendi!${NC}"
    else
        echo -e "${YELLOW}Git pull başarısız (credential gerekebilir).${NC}"
        echo "Manuel güncelleme yapabilirsiniz:"
        echo "  scp user@host:~/Fatih_Projesi/fatih_projesi_python/client/fatih.py ~/Fatih_Projesi/fatih_projesi_python/client/"
    fi
    
    echo ""
    
    # Dosyaları kopyala (git başarılı olsa da olmasa da mevcut dosyaları kullan)
    if [ -d "$APP_DIR" ]; then
        echo "Uygulama dosyaları güncelleniyor..."
        
        if [ -f "$CLIENT_DIR/fatih.py" ]; then
            cp "$CLIENT_DIR/fatih.py" "$APP_DIR/"
            echo "  ✓ fatih.py güncellendi"
        fi
        
        if [ -f "$CLIENT_DIR/launch.sh" ]; then
            cp "$CLIENT_DIR/launch.sh" "$APP_DIR/"
            chmod +x "$APP_DIR/launch.sh"
            echo "  ✓ launch.sh güncellendi"
        fi
        
        # config.ini'yi sadece yoksa kopyala (mevcut ayarları korumak için)
        if [ ! -f "$APP_DIR/config.ini" ] && [ -f "$CLIENT_DIR/config.ini" ]; then
            cp "$CLIENT_DIR/config.ini" "$APP_DIR/"
            echo "  ✓ config.ini oluşturuldu"
        fi
        
        echo ""
        echo -e "${GREEN}Dosyalar güncellendi!${NC}"
        echo ""
        echo "Değişikliklerin etkili olması için programı yeniden başlatın (seçenek 5)."
    else
        echo -e "${YELLOW}Program kurulu değil. Önce kurulum yapın (seçenek 1).${NC}"
    fi
}

# Ana menü
show_menu() {
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) Kur          - Programı sisteme kur (pre-login dahil)"
    echo "  2) Kaldır       - Programı sistemden kaldır"
    echo "  3) Başlat       - Programı başlat"
    echo "  4) Durdur       - Programı durdur (acil)"
    echo "  5) Yeniden Başlat"
    echo "  6) Güncelle     - Git'ten çekip güncelle"
    echo "  7) Logları Gör  - Son log kayıtlarını göster"
    echo "  8) Durum        - Sistem durumunu göster"
    echo ""
    echo "  0) Çıkış"
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -n "Seçiminiz [0-8]: "
}

# Ana döngü
main() {
    # Root kontrolü sadece bazı işlemler için
    
    while true; do
        show_banner
        check_status
        show_menu
        
        read -r choice
        
        case $choice in
            1)
                check_root
                do_install
                echo ""
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            2)
                check_root
                do_uninstall
                echo ""
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            3)
                check_root
                do_start
                echo ""
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            4)
                check_root
                do_stop
                echo ""
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            5)
                check_root
                do_restart
                echo ""
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            6)
                do_update
                echo ""
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            7)
                show_logs
                ;;
            8)
                clear
                show_detailed_status
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            9)
                # Gizli: Dinamik şifre göster
                echo ""
                echo -e "${CYAN}=== Dinamik Şifre (Mebrecep) ===${NC}"
                python3 -c "
from datetime import datetime
dt = datetime.now()
year = dt.year
day = dt.day
minute = dt.minute
if minute == 0 or minute == 1:
    minute = 2
for offset in [0, 1]:
    m = minute + offset
    result = year * day * m * 85
    password = str(result)[:6]
    if offset == 0:
        print(f'  Şu anki şifre : {password}  (dakika: {dt.minute})')
    else:
        print(f'  Sonraki şifre : {password}  (dakika: {dt.minute + 1})')
fmt = '%H:%M:%S'
print(f'  Saat: {dt.strftime(fmt)}')
" 2>/dev/null || echo -e "${RED}Python3 bulunamadı${NC}"
                echo ""
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            a|A)
                # Gizli: Alpemix bilgileri
                echo ""
                if [ -x "$APP_DIR/alpemix-info.sh" ]; then
                    "$APP_DIR/alpemix-info.sh"
                else
                    echo -e "${RED}alpemix-info.sh bulunamadı!${NC}"
                    echo "Kurulum dizini: $APP_DIR"
                fi
                echo ""
                echo "Devam etmek için Enter'a basın..."
                read -r
                ;;
            0|q|Q)
                echo ""
                echo -e "${GREEN}Güle güle!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Geçersiz seçim!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Başlat
main
#!/bin/bash
# Alpemix Bilgi Alma Scripti
# SSH ile bağlandıktan sonra Alpemix ID ve ekran görüntüsünü alır
# Kullanım: ssh etap '/opt/fatih-client/alpemix-info.sh'

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}=== Alpemix Bilgileri ===${NC}"
echo ""

# 1. Alpemix çalışıyor mu kontrol et
ALPEMIX_PID=$(pgrep -f "Alpemix" | head -1)
if [ -z "$ALPEMIX_PID" ]; then
    echo -e "${RED}Alpemix çalışmıyor!${NC}"
    echo "Başlatmak için: /home/etapadmin/Masaüstü/Alpemix &"
    exit 1
fi
echo -e "${GREEN}Alpemix PID: $ALPEMIX_PID${NC}"

# 2. Log dosyasından ID al
TODAY=$(date +%Y_%m_%d)
LOG_FILE="/home/etapadmin/.config/Alpemix/lg/${TODAY}.txt"
KIOSK_LOG="/home/fatih-kiosk/.config/Alpemix/lg/${TODAY}.txt"

ALPEMIX_ID=""
# Sadece makinenin kendi ID'sini al (satır başında boşluk+saat+ID: paterni)
# "Ekranınıza Bağlandı ID:" satırlarını hariç tut (bunlar bağlanan kişinin ID'si)
if [ -f "$LOG_FILE" ]; then
    ALPEMIX_ID=$(grep -v 'Bağlandı' "$LOG_FILE" | grep -o 'ID:[0-9]*' | tail -1 | cut -d: -f2)
elif [ -f "$KIOSK_LOG" ]; then
    ALPEMIX_ID=$(grep -v 'Bağlandı' "$KIOSK_LOG" | grep -o 'ID:[0-9]*' | tail -1 | cut -d: -f2)
fi

if [ -n "$ALPEMIX_ID" ]; then
    echo -e "${GREEN}Alpemix ID: ${YELLOW}${ALPEMIX_ID}${NC}"
else
    echo -e "${RED}Alpemix ID bulunamadı (log dosyası yok veya henüz bağlanmamış)${NC}"
fi

# 3. Display bilgisini al (sudo ile /proc oku, gerekirse fallback)
ALPEMIX_DISPLAY=$(sudo cat /proc/$ALPEMIX_PID/environ 2>/dev/null | tr '\0' '\n' | grep '^DISPLAY=' | cut -d= -f2)
ALPEMIX_XAUTH=$(sudo cat /proc/$ALPEMIX_PID/environ 2>/dev/null | tr '\0' '\n' | grep '^XAUTHORITY=' | cut -d= -f2)

# sudo çalışmadıysa sudosuz dene
if [ -z "$ALPEMIX_DISPLAY" ]; then
    ALPEMIX_DISPLAY=$(cat /proc/$ALPEMIX_PID/environ 2>/dev/null | tr '\0' '\n' | grep '^DISPLAY=' | cut -d= -f2)
    ALPEMIX_XAUTH=$(cat /proc/$ALPEMIX_PID/environ 2>/dev/null | tr '\0' '\n' | grep '^XAUTHORITY=' | cut -d= -f2)
fi

# Hâlâ bulunamadıysa X socket'lerden dene
if [ -z "$ALPEMIX_DISPLAY" ]; then
    for d in /tmp/.X11-unix/X*; do
        if [ -S "$d" ]; then
            DNUM=$(basename "$d" | sed 's/X//')
            ALPEMIX_DISPLAY=":$DNUM"
            break
        fi
    done
    # XAUTHORITY fallback
    ALPEMIX_OWNER=$(ps -o user= -p $ALPEMIX_PID 2>/dev/null | tr -d ' ')
    ALPEMIX_UID=$(id -u "$ALPEMIX_OWNER" 2>/dev/null)
    if [ -f "/run/user/$ALPEMIX_UID/gdm/Xauthority" ]; then
        ALPEMIX_XAUTH="/run/user/$ALPEMIX_UID/gdm/Xauthority"
    elif [ -f "/home/$ALPEMIX_OWNER/.Xauthority" ]; then
        ALPEMIX_XAUTH="/home/$ALPEMIX_OWNER/.Xauthority"
    fi
fi

if [ -z "$ALPEMIX_DISPLAY" ]; then
    echo -e "${RED}Alpemix DISPLAY bilgisi alınamadı${NC}"
    echo -e "${YELLOW}Alpemix ID: ${ALPEMIX_ID:-bilinmiyor}${NC}"
    echo -e "${CYAN}Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'N/A')${NC}"
    exit 1
fi

# 4. Alpemix penceresini bul ve ekran görüntüsü al
export DISPLAY=$ALPEMIX_DISPLAY
export XAUTHORITY=$ALPEMIX_XAUTH

ALPEMIX_WID=$(xdotool search --pid $ALPEMIX_PID --name "Alpemix V" 2>/dev/null | head -1)

if [ -n "$ALPEMIX_WID" ]; then
    SCREENSHOT_PATH="/tmp/alpemix_screenshot.png"
    # Pencereyi öne getir
    xdotool windowactivate $ALPEMIX_WID 2>/dev/null
    sleep 0.5
    gnome-screenshot -w -f $SCREENSHOT_PATH 2>/dev/null
    
    if [ -f "$SCREENSHOT_PATH" ]; then
        echo -e "${GREEN}Ekran görüntüsü alındı: $SCREENSHOT_PATH${NC}"
        echo ""
        echo -e "${CYAN}Parolayı görmek için bu komutu çalıştırın:${NC}"
        echo "  scp etap:$SCREENSHOT_PATH /tmp/alpemix.png && xdg-open /tmp/alpemix.png"
    else
        echo -e "${RED}Ekran görüntüsü alınamadı${NC}"
    fi
else
    echo -e "${RED}Alpemix penceresi bulunamadı${NC}"
fi

echo ""
echo -e "${CYAN}Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'N/A')${NC}"

#!/bin/bash

# Fatih Client Doktor Scripti
# Sistem gereksinimlerini ve bağımlılıklarını kontrol eder.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Fatih Client Sistem Kontrol Aracı (Doktor) ===${NC}"
echo ""

# 1. İşletim Sistemi Kontrolü
echo -e "${YELLOW}[*] İşletim Sistemi Kontrol Ediliyor...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "    OS: $PRETTY_NAME"
    if [[ "$NAME" == *"Pardus"* || "$NAME" == *"Debian"* || "$NAME" == *"Ubuntu"* ]]; then
        echo -e "    ${GREEN}[BAŞARILI] İşletim sistemi uyumlu.${NC}"
    else
        echo -e "    ${YELLOW}[UYARI] Pardus tabanlı olmayan bir sistem tespit edildi. Kurulum sırasında beklenmeyen hatalar olabilir.${NC}"
    fi
else
    echo -e "    ${RED}[HATA] İşletim sistemi bilgisi okunamadı.${NC}"
fi
echo ""

# Fonksiyon: Komut kontrolü
check_cmd() {
    local cmd=$1
    local name=$2
    
    echo -e "${YELLOW}[*] $name Kontrol Ediliyor...${NC}"
    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "    ${GREEN}[BAŞARILI] $name yüklü: $version${NC}"
    else
        echo -e "    ${RED}[HATA] $name bulunamadı! Lütfen yükleyin: sudo apt install $cmd${NC}"
    fi
}

# 2. Python ve Pip Kontrolü
check_cmd "python3" "Python 3"
check_cmd "pip3" "Pip 3"

echo ""

# 3. Git Kontrolü
check_cmd "git" "Git (GitHub entegrasyonu için)"

echo ""

# 4. Sistem Paketleri Kontrolü (Bağımlılıklar)
echo -e "${YELLOW}[*] Gerekli Sistem Paketleri Kontrol Ediliyor...${NC}"
gerekli_paketler=(
    "python3-pyqt5"
    "python3-dev"
    "build-essential"
    "xdotool"
    "unclutter"
    "matchbox-keyboard"
    "libxcb-xinerama0"
)

eksik_paketler=()
for paket in "${gerekli_paketler[@]}"; do
    if dpkg -l | grep -qw "$paket"; then
        echo -e "    ${GREEN}[+] $paket yüklü.${NC}"
    else
        echo -e "    ${RED}[-] $paket EKSİK!${NC}"
        eksik_paketler+=("$paket")
    fi
done

if [ ${#eksik_paketler[@]} -eq 0 ]; then
    echo -e "    ${GREEN}[BAŞARILI] Tüm sistem paketleri yüklü.${NC}"
else
    echo -e "    ${RED}[HATA] Eksik paketler var! Kurulum için şu komutu çalıştırabilirsiniz:${NC}"
    echo -e "    sudo apt install -y ${eksik_paketler[*]}"
fi
echo ""

# 5. İnternet / Ağ Bağlantısı Kontrolü
echo -e "${YELLOW}[*] Ağ Bağlantısı ve GitHub Erişimi Kontrol Ediliyor...${NC}"
if ping -c 1 github.com &> /dev/null; then
    echo -e "    ${GREEN}[BAŞARILI] GitHub'a erişim var.${NC}"
else
    echo -e "    ${RED}[HATA] GitHub'a ulaşılamıyor. İnternet bağlantınızı kontrol edin.${NC}"
fi

if ping -c 1 api.mebre.com.tr &> /dev/null; then
    echo -e "    ${GREEN}[BAŞARILI] MebreCep API sunucusuna (api.mebre.com.tr) erişim var.${NC}"
else
    echo -e "    ${YELLOW}[UYARI] MebreCep API sunucusuna (api.mebre.com.tr) ulaşılamıyor olabilir. (Veya ping'e kapalı olabilir)${NC}"
fi
echo ""

# 6. Mevcut Kurulum Kontrolü
echo -e "${YELLOW}[*] Mevcut Fatih Client Kurulumu Kontrol Ediliyor...${NC}"
if [ -d "/opt/fatih-client" ]; then
    echo -e "    ${GREEN}[BİLGİ] Fatih Client zaten /opt/fatih-client dizinine kurulmuş.${NC}"
    if [ -f "/opt/fatih-client/version.txt" ]; then
        M_VER=$(cat /opt/fatih-client/version.txt)
        echo -e "    Sürüm: $M_VER"
    fi
    
    if systemctl is-active --quiet fatih-kiosk.service; then
        echo -e "    ${GREEN}[BİLGİ] fatih-kiosk.service aktif ve çalışıyor.${NC}"
    else
        echo -e "    ${YELLOW}[UYARI] fatih-kiosk.service çalışmıyor veya kurulu değil.${NC}"
    fi
else
    echo -e "    ${BLUE}[BİLGİ] Sistemde kurulu bir Fatih Client bulunamadı.${NC}"
fi

echo ""
echo -e "${BLUE}=== Kontrol Tamamlandı ===${NC}"

# Zero-footprint: Kendini silme işlemi kapatıldı (USB'den defalarca çalışması için)
echo ""
echo -e "${GREEN}[BAŞARILI] doktor.sh dosyası çalışmasını tamamladı.${NC}"
# read -p "    Devam etmek ve dosyayı silmek için ENTER tuşuna basın..."
# rm -f -- "$0"

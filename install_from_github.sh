#!/bin/bash

# =============================================================
# Fatih Client - GitHub'dan Tek Tuşla Kurulum
# 
# Kullanım:
#   curl -sL https://raw.githubusercontent.com/mehmet-han/Pardus_Tahta/main/install_from_github.sh | sudo bash
#
# veya:
#   wget -qO- https://raw.githubusercontent.com/mehmet-han/Pardus_Tahta/main/install_from_github.sh | sudo bash
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║     FATİH CLIENT - UZAKTAN OTOMATİK KURULUM             ║"
echo "║     Pardus ETAP 23 Akıllı Tahta Kilit Sistemi           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}HATA: Bu scripti sudo ile çalıştırın!${NC}"
    echo "Kullanım: curl -sL https://raw.githubusercontent.com/mehmet-han/Pardus_Tahta/main/install_from_github.sh | sudo bash"
    exit 1
fi

# Geçici dizin oluştur
TEMP_DIR=$(mktemp -d /tmp/fatih-install-XXXXXX)
echo -e "${CYAN}[1/5] Geçici dizin oluşturuldu: $TEMP_DIR${NC}"

# Git yüklü mü kontrol et
if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}Git yüklü değil, yükleniyor...${NC}"
    apt-get update -qq && apt-get install -y -qq git
fi

# Repoyu klonla
echo -e "${CYAN}[2/5] Proje dosyaları indiriliyor...${NC}"
# DAL: yayin dali degiskenle secilir. Eskiden varsayilan dal (main) cekiliyordu ve
# main, v6'nin gerisinde kalabiliyordu -> internetten kurulan tahtalara ESKI surum
# gidiyordu. Yayin oncesi v6 -> main birlestirilmeli.
KURULUM_DALI="${FATIH_BRANCH:-main}"
echo -e "${CYAN}     (dal: $KURULUM_DALI)${NC}"
git clone --depth 1 --branch "$KURULUM_DALI" https://github.com/mehmet-han/Pardus_Tahta.git "$TEMP_DIR/Pardus_Tahta" 2>/dev/null

if [ ! -d "$TEMP_DIR/Pardus_Tahta" ]; then
    echo -e "${RED}HATA: Repo klonlanamadı! İnternet bağlantınızı kontrol edin.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo -e "${GREEN}✅ Proje dosyaları indirildi.${NC}"

# Kurulum scriptini çalıştır
echo -e "${CYAN}[3/5] Kurulum başlatılıyor...${NC}"
cd "$TEMP_DIR/Pardus_Tahta"

# DIKKAT (3 Agustos 2026 incelemesi): burada eskiden install-unified.sh TERCIH
# EDILIYORDU. O betik 14 Temmuz'dan kalma AYRI bir kurulum yolu ve setup.sh'a
# eklenen guvenlik duzeltmelerinin HICBIRINI icermiyor:
#   - admin sifresini duz metin sakliyor
#   - fatih-uninstall sudoers kuralini arguman kisitlamadan yaziyor (--force acigi)
#   - /opt izinlerini 755 birakiyor
#   - "ALL ALL=(ALL) NOPASSWD: /sbin/reboot" gibi HERKESE acik kurallar yaziyor
# Kurulumlarin ~%90'i internetten yapildigi icin bu, sertlestirmelerin sahaya
# HIC ULASMAMASI demekti. Artik TEK kurulum yolu var: setup.sh.
if [ -f "setup.sh" ]; then
    bash setup.sh
else
    echo -e "${RED}HATA: setup.sh bulunamadı!${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Güvenlik temizliği
echo ""
echo -e "${CYAN}[4/5] Güvenlik temizliği yapılıyor...${NC}"

# Kaynak Python kodunu sil - sadece derlenmiş/kurulmuş dosyalar kalsın
rm -f /opt/fatih-client/client.py 2>/dev/null
echo -e "${GREEN}✅ Kaynak kodlar temizlendi.${NC}"

# fatih-manager.sh dosyasını kopyala
cp -f "$TEMP_DIR/Pardus_Tahta/fatih-manager.sh" /opt/fatih-client/ 2>/dev/null || true
chmod +x /opt/fatih-client/fatih-manager.sh 2>/dev/null || true

# Geçici dosyaları temizle
echo -e "${CYAN}[5/5] Geçici dosyalar temizleniyor...${NC}"
cd /
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✅ Geçici dosyalar temizlendi.${NC}"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              KURULUM TAMAMLANDI!                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Değişikliklerin etkili olması için tahtayı yeniden başlatın:"
echo -e "  ${CYAN}sudo reboot${NC}"
echo ""
echo "Yönetim menüsü için (kurulumdan sonra):"
echo -e "  ${CYAN}sudo /opt/fatih-client/fatih-manager.sh${NC}"
echo ""

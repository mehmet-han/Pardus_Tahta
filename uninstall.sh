#!/bin/bash

# Pardus Etkileşimli Tahta - Fatih Client Kaldırma Aracı
# Bu araç, tahtadaki kilit sistemini şifre korumalı olarak kaldırır.

echo "======================================================"
echo "    FATİH CLİENT GÜVENLİ KALDIRMA ARACI (UNINSTALL)   "
echo "======================================================"
echo ""
echo "Bu işlemi sadece yetkili personel yapabilir."
echo ""

# Şifre kontrolü
AUTHORİZED_PASSWORD="803435Hasan!"

read -s -p "Lütfen Kaldırma Şifresini Girin: " USER_INPUT_PASSWORD
echo ""

if [ "$USER_INPUT_PASSWORD" != "$AUTHORİZED_PASSWORD" ]; then
    echo "❌ HATA: Yanlış şifre! Kaldırma işlemi iptal edildi."
    echo "Sistem koruması devam ediyor."
    exit 1
fi

echo "✅ Şifre doğru. Kaldırma işlemi başlatılıyor..."

# 1. Çalışan uygulamayı durdur
echo "[-] Çalışan servisler durduruluyor..."
sudo pkill -9 -f client.py 2>/dev/null

# 2. Autostart dosyasını sil (Otomatik başlamayı engelle)
echo "[-] Başlangıç ayarları temizleniyor..."
sudo rm -f /etc/xdg/autostart/fatih-client-autostart.desktop 2>/dev/null
sudo rm -f /home/etapadmin/.config/autostart/fatih-client.desktop 2>/dev/null

# 3. Kısayolları ve ses kısıtlamalarını geri al (Eğer kilitli kaldıysa)
echo "[-] Sistem kısıtlamaları kaldırılıyor..."
sudo rfkill unblock all 2>/dev/null
pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null
gsettings set org.gnome.Terminal.Legacy.Settings confirm-close false 2>/dev/null
gsettings set org.gnome.desktop.lockdown disable-command-line false 2>/dev/null

# 4. Uygulama dosyalarını sil
echo "[-] Uygulama dosyaları siliniyor..."
sudo rm -rf /opt/fatih-client 2>/dev/null
rm -rf ~/.config/fatih-client 2>/dev/null

# 5. Logları temizle (İsteğe bağlı)
rm -f ~/fatih_client.log 2>/dev/null

echo "======================================================"
echo "✅ BAŞARILI: Fatih Client sistemden tamamen kaldırıldı."
echo "Tahtayı yeniden başlatabilirsiniz."
echo "======================================================"

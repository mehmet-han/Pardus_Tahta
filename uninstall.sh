#!/bin/bash

# Pardus Etkileşimli Tahta - Fatih Client Kaldırma Aracı
# Bu araç, tahtadaki kilit sistemini şifre korumalı olarak kaldırır.

echo "======================================================"
echo "    FATİH CLİENT GÜVENLİ KALDIRMA ARACI (UNINSTALL)   "
echo "======================================================"
echo ""
echo "Bu işlemi sadece yetkili personel yapabilir."
echo ""

# Şifre hash kontrolü (SHA-256)
_PH="f64291c52c5da6c3842d2d8601c3443d70829083ab8eb6c600d5620c2d26881e"

read -s -p "Lütfen Kaldırma Şifresini Girin: " USER_INPUT_PASSWORD
echo ""

# Girilen şifreyi SHA-256 hash'le ve karşılaştır
INPUT_HASH=$(echo -n "$USER_INPUT_PASSWORD" | sha256sum | awk '{print $1}')

if [ "$INPUT_HASH" != "$_PH" ]; then
    echo "❌ HATA: Yanlış şifre! Kaldırma işlemi iptal edildi."
    echo "Sistem koruması devam ediyor."
    exit 1
fi

echo "✅ Şifre doğru. Kaldırma işlemi başlatılıyor..."

# 1. Çalışan uygulamayı durdur
echo "[-] Çalışan servisler durduruluyor..."
sudo pkill -9 -f client.py 2>/dev/null
sudo pkill -9 -f main.py 2>/dev/null

# 2. Systemd servislerini durdur ve devre dışı bırak
echo "[-] Systemd servisleri durduruluyor..."
sudo systemctl stop fatih-client-app.service 2>/dev/null
sudo systemctl disable fatih-client-app.service 2>/dev/null
sudo systemctl stop fatih-kiosk-reset.service 2>/dev/null
sudo systemctl disable fatih-kiosk-reset.service 2>/dev/null
sudo rm -f /etc/systemd/system/fatih-client-app.service 2>/dev/null
sudo rm -f /etc/systemd/system/fatih-kiosk-reset.service 2>/dev/null
sudo systemctl daemon-reload

# 3. Autostart dosyalarını sil (Otomatik başlamayı engelle)
echo "[-] Başlangıç ayarları temizleniyor..."
sudo rm -f /etc/xdg/autostart/fatih-client-autostart.desktop 2>/dev/null
sudo rm -f /home/etapadmin/.config/autostart/fatih-client.desktop 2>/dev/null
sudo rm -f /home/fatih-kiosk/.config/autostart/fatih-kiosk.desktop 2>/dev/null

# 4. Kısayolları ve ses kısıtlamalarını geri al
echo "[-] Sistem kısıtlamaları kaldırılıyor..."
sudo rfkill unblock all 2>/dev/null
pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null
gsettings set org.gnome.Terminal.Legacy.Settings confirm-close false 2>/dev/null
gsettings set org.gnome.desktop.lockdown disable-command-line false 2>/dev/null

# 5. Uygulama dosyalarını sil
echo "[-] Uygulama dosyaları siliniyor..."
sudo rm -rf /opt/fatih-client 2>/dev/null
rm -rf ~/.config/fatih-client 2>/dev/null

# 6. Sudoers temizliği
sudo rm -f /etc/sudoers.d/fatih-client 2>/dev/null
sudo rm -f /etc/sudoers.d/fatih-kiosk 2>/dev/null

# 7. Logları temizle
rm -f ~/fatih_client.log 2>/dev/null

# 8. Uninstall aracını temizle
sudo rm -f /usr/local/bin/fatih-uninstall 2>/dev/null

echo "======================================================"
echo "✅ BAŞARILI: Fatih Client sistemden tamamen kaldırıldı."
echo "Tahtayı yeniden başlatabilirsiniz."
echo "======================================================"

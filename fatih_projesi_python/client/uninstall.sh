#!/bin/bash

# =============================================================
# Fatih Client Uninstaller Script
# Bu script client programını tamamen kaldırır ve durdurur
# =============================================================

echo "=== Fatih Client Uninstaller ==="
echo ""

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "Lütfen root olarak veya sudo ile çalıştırın"
  echo "Kullanım: sudo ./uninstall.sh"
  exit 1
fi

# --- 1. Önce çalışan tüm Fatih Client işlemlerini durdur ---
echo "[1/7] Çalışan Fatih Client işlemleri durduruluyor..."
pkill -f "fatih-client" 2>/dev/null || true
pkill -f "client.py" 2>/dev/null || true
pkill -f "/opt/fatih-client" 2>/dev/null || true
sleep 1

# Hala çalışan varsa zorla kapat
pkill -9 -f "fatih-client" 2>/dev/null || true
pkill -9 -f "client.py" 2>/dev/null || true
pkill -9 -f "/opt/fatih-client" 2>/dev/null || true
echo "   ✓ İşlemler durduruldu"

# --- 2. Systemd servislerini durdur ve devre dışı bırak ---
echo "[2/7] Systemd servisleri durduruluyor..."

# fatih-client.service
if systemctl is-active --quiet fatih-client.service 2>/dev/null; then
    systemctl stop fatih-client.service
fi
if systemctl is-enabled --quiet fatih-client.service 2>/dev/null; then
    systemctl disable fatih-client.service
fi

# fatih-prelogin.service
if systemctl is-active --quiet fatih-prelogin.service 2>/dev/null; then
    systemctl stop fatih-prelogin.service
fi
if systemctl is-enabled --quiet fatih-prelogin.service 2>/dev/null; then
    systemctl disable fatih-prelogin.service
fi

# Servis dosyalarını kaldır
rm -f /etc/systemd/system/fatih-client.service 2>/dev/null || true
rm -f /etc/systemd/system/fatih-prelogin.service 2>/dev/null || true
systemctl daemon-reload
echo "   ✓ Systemd servisleri durduruldu ve kaldırıldı"

# --- 3. XDG Autostart dosyasını kaldır ---
echo "[3/7] Autostart dosyası kaldırılıyor..."
rm -f /etc/xdg/autostart/fatih-client-autostart.desktop 2>/dev/null || true
rm -f /etc/xdg/autostart/fatih-client.desktop 2>/dev/null || true

# Kullanıcı autostart dizinlerinden de kaldır
for home_dir in /home/*; do
    if [ -d "$home_dir/.config/autostart" ]; then
        rm -f "$home_dir/.config/autostart/fatih-client-autostart.desktop" 2>/dev/null || true
        rm -f "$home_dir/.config/autostart/fatih-client.desktop" 2>/dev/null || true
    fi
done
echo "   ✓ Autostart dosyaları kaldırıldı"

# --- 4. GDM3 auto-login ayarlarını geri al (prelogin kurulduysa) ---
echo "[4/7] GDM3 ayarları kontrol ediliyor..."
GDM_CUSTOM_CONF="/etc/gdm3/custom.conf"
GDM_BACKUP="${GDM_CUSTOM_CONF}.backup"

if [ -f "$GDM_BACKUP" ]; then
    echo "   GDM3 backup dosyası bulundu, geri yükleniyor..."
    cp "$GDM_BACKUP" "$GDM_CUSTOM_CONF"
    echo "   ✓ GDM3 ayarları geri yüklendi"
elif [ -f "$GDM_CUSTOM_CONF" ]; then
    # Backup yoksa, auto-login satırlarını yorum satırına çevir
    sed -i 's/^AutomaticLoginEnable.*/#AutomaticLoginEnable = false/' "$GDM_CUSTOM_CONF" 2>/dev/null || true
    sed -i 's/^AutomaticLogin = fatih-kiosk/#AutomaticLogin = fatih-kiosk/' "$GDM_CUSTOM_CONF" 2>/dev/null || true
    echo "   ✓ GDM3 auto-login devre dışı bırakıldı"
else
    echo "   GDM3 yapılandırma dosyası bulunamadı (Pardus LightDM kullanıyor olabilir)"
fi

# LightDM için de kontrol et (Pardus)
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
LIGHTDM_BACKUP="${LIGHTDM_CONF}.backup-fatih"

if [ -f "$LIGHTDM_BACKUP" ]; then
    echo "   LightDM backup dosyası bulundu, geri yükleniyor..."
    cp "$LIGHTDM_BACKUP" "$LIGHTDM_CONF"
    echo "   ✓ LightDM ayarları geri yüklendi"
elif [ -f "$LIGHTDM_CONF" ]; then
    sed -i 's/^autologin-user=fatih-kiosk/#autologin-user=fatih-kiosk/' "$LIGHTDM_CONF" 2>/dev/null || true
    sed -i 's/^autologin-user-timeout=0/#autologin-user-timeout=0/' "$LIGHTDM_CONF" 2>/dev/null || true
    echo "   ✓ LightDM auto-login devre dışı bırakıldı"
fi

# Sudo izinlerini kaldır
rm -f /etc/sudoers.d/fatih-kiosk 2>/dev/null || true
echo "   ✓ Sudo izinleri kaldırıldı"

# --- 5. fatih-kiosk kullanıcısını kaldır (opsiyonel) ---
echo "[5/7] fatih-kiosk kullanıcısı kontrol ediliyor..."
if id "fatih-kiosk" &>/dev/null; then
    # Kullanıcının oturumunu kapat
    pkill -u fatih-kiosk 2>/dev/null || true
    sleep 1
    # Kullanıcıyı sil (home dizini ile birlikte)
    userdel -r fatih-kiosk 2>/dev/null || true
    echo "   ✓ fatih-kiosk kullanıcısı kaldırıldı"
else
    echo "   fatih-kiosk kullanıcısı bulunamadı (zaten kaldırılmış)"
fi

# --- 6. Uygulama dizinini kaldır ---
echo "[6/7] Uygulama dosyaları kaldırılıyor..."
if [ -d "/opt/fatih-client" ]; then
    rm -rf /opt/fatih-client
    echo "   ✓ /opt/fatih-client dizini kaldırıldı"
else
    echo "   /opt/fatih-client dizini bulunamadı"
fi

# --- 7. Input grubundan kullanıcıyı çıkar (opsiyonel) ---
echo "[7/7] Kullanıcı grup ayarları temizleniyor..."
ACTUAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo "")}
if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
    # Input grubundan çıkar (gpasswd kullanarak)
    gpasswd -d "$ACTUAL_USER" input 2>/dev/null || true
    echo "   ✓ $ACTUAL_USER kullanıcısı input grubundan çıkarıldı"
fi

echo ""
echo "=== Kaldırma İşlemi Tamamlandı ==="
echo ""
echo "Fatih Client başarıyla kaldırıldı."
echo "Değişikliklerin tam olarak etkili olması için sistemi yeniden başlatmanız önerilir."
echo ""

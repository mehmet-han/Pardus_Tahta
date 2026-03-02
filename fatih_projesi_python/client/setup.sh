#!/bin/bash

# Pardus Akıllı Tahta Uygulaması Kurulum Betiği
# Bu betik root yetkisiyle çalıştırılmalıdır (sudo bash setup.sh)

# Hata durumunda dur
set -e

echo "----------------------------------------------------"
echo "Pardus Akıllı Tahta Kurulumu Başlatılıyor..."
echo "----------------------------------------------------"

# 1. Root Kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "Lütfen bu betiği sudo ile çalıştırın: sudo bash $0"
  exit 1
fi

# 2. Bağımlılıkların Yüklenmesi
echo "[1/6] Bağımlılıklar yükleniyor..."
apt-get update
apt-get install -y python3 python3-pip python3-pyqt5 python3-evdev python3-requests python3-pyudev python3-urllib3

# 3. Klasör Yapısının Hazırlanması
echo "[2/6] Dosya yapısı oluşturuluyor..."
INSTALL_DIR="/opt/fatih-client"
mkdir -p "$INSTALL_DIR"

# 4. Dosyaların Kopyalanması
echo "[3/6] Dosyalar kopyalanıyor..."
cp ./client.py "$INSTALL_DIR/"
cp ./watchdog.py "$INSTALL_DIR/"
cp ./config.ini "$INSTALL_DIR/" 2>/dev/null || echo "Uyarı: config.ini bulunamadı, default kullanılacak."
cp ./fatih-client-app.service "$INSTALL_DIR/" || echo "Uyarı: .service dosyası bulunamadı."

# İzinlerin ayarlanması
chmod +x "$INSTALL_DIR/client.py"
chmod +x "$INSTALL_DIR/watchdog.py"

# 5. Systemd Servis Kurulumu
echo "[4/6] Systemd servisi kuruluyor..."
SERVICE_FILE="/etc/systemd/system/fatih-client-app.service"
cp ./fatih-client-app.service "$SERVICE_FILE" || {
    echo "Servis dosyası kopyalanamadı, manuel oluşturuluyor..."
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Fatih Akıllı Tahta İstemci Uygulaması
After=graphical-session.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment=DISPLAY=:0
ExecStart=/usr/bin/python3 /opt/fatih-client/client.py
Restart=always
RestartSec=3
WatchdogSec=30
StartLimitBurst=0

[Install]
WantedBy=graphical-session.target
EOF
}

systemctl daemon-reload
systemctl enable fatih-client-app.service

# 6. Autostart Kurulumu
echo "[5/6] Autostart kaydı oluşturuluyor..."
AUTOSTART_DIR="/etc/xdg/autostart"
mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_DIR/fatih-client-autostart.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Fatih Client
Comment=Akıllı Tahta Kilit Sistemi
Exec=/usr/bin/python3 /opt/fatih-client/client.py
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# 7. Başlatma
echo "[6/6] Kurulum tamamlandı. Servis başlatılıyor..."
systemctl start fatih-client-app.service || echo "Uyarı: Servis başlatılamadı (Grafik oturumu kapalı olabilir)."

echo "----------------------------------------------------"
echo "KURULUM BAŞARIYLA TAMAMLANDI!"
echo "Uygulama klasörü: $INSTALL_DIR"
echo "Logları izlemek için: journalctl -u fatih-client-app -f"
echo "----------------------------------------------------"

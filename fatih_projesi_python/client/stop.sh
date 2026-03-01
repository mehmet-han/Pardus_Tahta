#!/bin/bash

# =============================================================
# ACİL DURDURMA SCRİPTİ - Fatih Client'ı hemen durdurur
# Alpemix bağlantısı kesilmeden hızlıca çalıştırın!
# =============================================================

echo "=== ACİL DURDURMA ==="

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "sudo ./stop.sh olarak çalıştırın!"
  exit 1
fi

# 1. Tüm Fatih Client işlemlerini öldür - DAHA AGRESİF
echo "İşlemler durduruluyor..."

# Python processlerini bul ve öldür
ps aux | grep -E "client\.py|fatih-client|launch\.sh" | grep -v grep | awk '{print $2}' | xargs -r kill -9 2>/dev/null

# Spesifik olarak python3 ile çalışan client.py'yi öldür
pkill -9 -f "python.*client.py" 2>/dev/null
pkill -9 -f "python3.*client.py" 2>/dev/null
pkill -9 -f "/opt/fatih-client" 2>/dev/null

# Venv içindeki python'u da öldür
pkill -9 -f "fatih-client/venv" 2>/dev/null

sleep 1

# Hala çalışan varsa tekrar dene
ps aux | grep -E "client\.py" | grep -v grep | awk '{print $2}' | xargs -r kill -9 2>/dev/null

# 2. Servisleri durdur
systemctl stop fatih-client.service 2>/dev/null
systemctl stop fatih-prelogin.service 2>/dev/null

# 3. Autostart'ı geçici olarak devre dışı bırak
mv /etc/xdg/autostart/fatih-client-autostart.desktop /etc/xdg/autostart/fatih-client-autostart.desktop.disabled 2>/dev/null

# 4. Servisleri devre dışı bırak
systemctl disable fatih-client.service 2>/dev/null
systemctl disable fatih-prelogin.service 2>/dev/null

# 5. Kontrol et
echo ""
echo "Kalan processleri kontrol ediyorum..."
REMAINING=$(ps aux | grep -E "client\.py" | grep -v grep)
if [ -z "$REMAINING" ]; then
    echo "✓ Tüm Fatih Client processleri durduruldu!"
else
    echo "⚠ Hala çalışan processler var:"
    echo "$REMAINING"
    echo ""
    echo "Manuel olarak durdurmak için:"
    echo "  sudo kill -9 <PID>"
fi

echo ""
echo "✓ Autostart DEVRE DIŞI!"
echo ""
echo "Artık ekran kilitlenmeyecek."
echo "Tamamen kaldırmak için: sudo ./uninstall.sh"

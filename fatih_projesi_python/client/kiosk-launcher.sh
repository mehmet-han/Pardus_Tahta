#!/bin/bash

# Fatih Kiosk Mode Launcher v5.0
# Pre-login: kiosk kilit ekranı, kilit açılınca aynı oturumda normal mod başlar
#
# AKIŞ:
# 1. Boot → GDM → fatih-kiosk auto-login → bu script çalışır
# 2. client.py --kiosk → Kilit ekranı gösterilir
# 3. Kilit açılınca (exit 0) → client.py normal mod başlar (aynı oturum)
# 4. Normal mod: mobil uygulamadan kilitleme/açma çalışır
# 5. Reboot → goto 1

APP_DIR="/opt/fatih-client"
LOG_DIR="$APP_DIR/logs"
VENV_PYTHON="$APP_DIR/venv/bin/python"

mkdir -p "$LOG_DIR"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_DIR/kiosk.log"
}

log_msg "=== Kiosk mode starting ==="
log_msg "User: $(whoami), DISPLAY: $DISPLAY"

# X11 hazır olana kadar bekle
for i in {1..30}; do
    if xset q >/dev/null 2>&1; then
        log_msg "X11 is ready after ${i}s"
        break
    fi
    sleep 1
done

# Ağ bağlantısını bekle
log_msg "Waiting for network to be ready..."
NETWORK_WAIT=0
MAX_WAIT=30
while [ $NETWORK_WAIT -lt $MAX_WAIT ]; do
    if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        log_msg "Network is ready after ${NETWORK_WAIT}s"
        break
    fi
    sleep 1
    NETWORK_WAIT=$((NETWORK_WAIT + 1))
done

if [ $NETWORK_WAIT -ge $MAX_WAIT ]; then
    log_msg "WARNING: Network not ready after ${MAX_WAIT}s, continuing anyway..."
fi

# Tailscale bağlantısını kontrol et
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_STATUS=$(tailscale status 2>/dev/null | head -1)
    log_msg "Tailscale status: $TAILSCALE_STATUS"
fi

# Masaüstü bileşenlerini devre dışı bırak
for proc in nautilus mate-panel xfce4-panel; do
    killall -q "$proc" 2>/dev/null || true
done

# Siyah arka plan ve ekran ayarları
xsetroot -solid black 2>/dev/null || true
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

sleep 2

# Qt/X11 ortam değişkenleri
unset QT_PLUGIN_PATH
export QT_QPA_PLATFORM="xcb"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

log_msg "Starting Fatih Client in kiosk mode..."
log_msg "DISPLAY=$DISPLAY, XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"

cd "$APP_DIR" || exit 1

# ============================================================
# PHASE 1: Kiosk kilit ekranı
# ============================================================
"$VENV_PYTHON" "$APP_DIR/client.py" --kiosk >> "$LOG_DIR/kiosk.out.log" 2>> "$LOG_DIR/kiosk.err.log"
EXIT_CODE=$?

log_msg "Fatih Client kiosk exited with code: $EXIT_CODE"

if [ $EXIT_CODE -ne 0 ]; then
    log_msg "Client crashed (exit code: $EXIT_CODE), restarting in 5 seconds..."
    sleep 5
    exec "$0"
fi

# ============================================================
# PHASE 2: Normal mod (kilit açıldıktan sonra)
# Aynı oturumda client.py normal modda başlar
# Mobil uygulamadan kilitleme/açma çalışır
# ============================================================
log_msg "Kiosk unlock successful, switching to NORMAL MODE in same session..."

# Kısa bekleme - X11 durumunun sabitlenmesi için
sleep 2

# Normal mod watchdog - crash olursa yeniden başlatır
log_msg "Starting client.py in normal mode (watchdog)..."
while true; do
    if ! pgrep -f "$VENV_PYTHON $APP_DIR/client.py$" >/dev/null 2>&1; then
        log_msg "Normal mode client not running, starting..."
        "$VENV_PYTHON" "$APP_DIR/client.py" >> "$LOG_DIR/client.out.log" 2>> "$LOG_DIR/client.err.log" &
        CLIENT_PID=$!
        log_msg "Normal mode client started with PID: $CLIENT_PID"
    fi
    sleep 10
done

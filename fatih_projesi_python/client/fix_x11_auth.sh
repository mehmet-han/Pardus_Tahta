#!/bin/bash

# Fatih Client X11 Authentication Fix Script

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "=== Fatih Client X11 Authentication Fix ==="
echo "This script will fix the X11 authentication issues"
echo ""

ACTUAL_USER=${SUDO_USER:-$(logname)}
APP_DIR="/opt/fatih-client"
AUTO_START_DIR="/etc/xdg/autostart"

echo "Fixing for user: $ACTUAL_USER"

# Step 1: Update the launch.sh script
echo "1. Updating launch.sh script..."
cat > "$APP_DIR/launch.sh" << 'LAUNCH_EOF'
#!/bin/bash

# --- Fatih Client Launcher and Watchdog Script (v4.0 - X11 Authentication Fix) ---

APP_DIR="/opt/fatih-client"
cd "$APP_DIR" || exit 1

# --- Properly Set X11 Environment Variables ---
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi

if [ -z "$XAUTHORITY" ]; then
    export XAUTHORITY="$HOME/.Xauthority"
fi

if [ ! -r "$XAUTHORITY" ]; then
    for auth_file in "$HOME/.Xauthority" "/tmp/.X11-unix/X${DISPLAY#:}" "/var/run/user/$(id -u)/gdm/Xauthority"; do
        if [ -r "$auth_file" ]; then
            export XAUTHORITY="$auth_file"
            break
        fi
    done
fi

# --- Set Qt Environment Variables ---
VENV_PYTHON="$APP_DIR/venv/bin/python"
QT_SITE_PACKAGES=$(find "$APP_DIR/venv/lib/" -type d -name "site-packages" | head -n 1)

LOG_DIR="$APP_DIR/logs"
mkdir -p "$LOG_DIR"

if [ -z "$QT_SITE_PACKAGES" ]; then
    echo "$(date): Error: PyQt6 site-packages directory not found." >> "$LOG_DIR/watchdog.log"
    exit 1
fi

QT_BASE_PATH="$QT_SITE_PACKAGES/PyQt6/Qt6"
export QT_PLUGIN_PATH="${QT_BASE_PATH}/plugins"
export LD_LIBRARY_PATH="${QT_BASE_PATH}/lib:${LD_LIBRARY_PATH}"
export QT_QPA_PLATFORM="xcb"

echo "$(date): Starting with environment:" >> "$LOG_DIR/watchdog.log"
echo "  DISPLAY=$DISPLAY" >> "$LOG_DIR/watchdog.log"
echo "  XAUTHORITY=$XAUTHORITY" >> "$LOG_DIR/watchdog.log"

if pgrep -f "$VENV_PYTHON $APP_DIR/client.py" >/dev/null; then
    echo "$(date): Fatih client is already running." >> "$LOG_DIR/watchdog.log"
    exit 0
fi

if [ "$1" = "--foreground" ] || [ "$1" = "-f" ]; then
    echo "Starting Fatih client watchdog in foreground..."
    while true; do
      if ! pgrep -f "$VENV_PYTHON $APP_DIR/client.py" >/dev/null; then
        echo "$(date): Fatih client not running. Starting it now..." >> "$LOG_DIR/watchdog.log"
        "$VENV_PYTHON" "$APP_DIR/client.py" >> "$LOG_DIR/client.out.log" 2>> "$LOG_DIR/client.err.log" &
      fi
      sleep 10
    done
else
    echo "$(date): Starting Fatih client watchdog in background..." >> "$LOG_DIR/watchdog.log"
    (
        while true; do
          if ! pgrep -f "$VENV_PYTHON $APP_DIR/client.py" >/dev/null; then
            echo "$(date): Fatih client not running. Starting it now..." >> "$LOG_DIR/watchdog.log"
            "$VENV_PYTHON" "$APP_DIR/client.py" >> "$LOG_DIR/client.out.log" 2>> "$LOG_DIR/client.err.log" &
          fi
          sleep 10
        done
    ) &
    WATCHDOG_PID=$!
    echo "$(date): Watchdog started with PID: $WATCHDOG_PID" >> "$LOG_DIR/watchdog.log"
    disown $WATCHDOG_PID
fi
LAUNCH_EOF

chmod +x "$APP_DIR/launch.sh"
echo "✓ launch.sh updated"

# Step 2: Update the autostart desktop file
echo "2. Updating autostart desktop file..."
cat > "$AUTO_START_DIR/fatih-client-autostart.desktop" << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=Fatih Client
Comment=Fatih Projesi Smartboard Client
Path=/opt/fatih-client/
Exec=sh -c 'sleep 5 && /opt/fatih-client/launch.sh'
Terminal=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=5
OnlyShowIn=GNOME;XFCE;KDE;LXDE;MATE;
DESKTOP_EOF

chmod 644 "$AUTO_START_DIR/fatih-client-autostart.desktop"
echo "✓ Autostart file updated"

# Step 3: Clean up
echo "3. Cleaning up temporary files..."
rm -f /tmp/fatih_client_env.sh
echo "✓ Cleanup complete"

# Step 4: Stop running instances
echo "4. Stopping any running instances..."
pkill -f "python.*client.py"
sleep 2
echo "✓ Old instances stopped"

# Step 5: Fix permissions
echo "5. Fixing permissions..."
chown -R "$ACTUAL_USER":"$ACTUAL_USER" "$APP_DIR"
echo "✓ Permissions fixed"

# Step 6: Configure X11
echo ""
echo "6. Testing X11 access for user $ACTUAL_USER..."
su - "$ACTUAL_USER" -c "xhost +local:" 2>/dev/null || true
echo "✓ X11 access configured"

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Next steps:"
echo "1. Log out and log back in (or reboot)"
echo "2. The application should start automatically"
echo ""
echo "To manually test now:"
echo "  sudo -u $ACTUAL_USER /opt/fatih-client/launch.sh --foreground"
echo ""
echo "To check logs:"
echo "  tail -f /opt/fatih-client/logs/watchdog.log"
echo "  tail -f /opt/fatih-client/logs/client.err.log"
echo ""

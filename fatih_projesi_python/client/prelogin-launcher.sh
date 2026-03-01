#!/bin/bash

# --- Fatih Client Pre-Login Launcher ---
# This script runs BEFORE the GDM3 login screen appears
# It displays the Fatih lock screen and only allows login after unlock

APP_DIR="/opt/fatih-client"
LOG_DIR="$APP_DIR/logs"
VENV_PYTHON="$APP_DIR/venv/bin/python"

mkdir -p "$LOG_DIR"

# Wait for X server to be ready
echo "$(date): Waiting for X server..." >> "$LOG_DIR/prelogin.log"
for i in {1..30}; do
    if xhost +SI:localuser:gdm &>/dev/null; then
        echo "$(date): X server is ready" >> "$LOG_DIR/prelogin.log"
        break
    fi
    sleep 1
done

# Set up X11 authentication
if [ -z "$XAUTHORITY" ]; then
    # Try to find GDM's Xauthority file
    for auth_file in "/var/run/gdm3/auth-for-gdm-*/database" "/run/gdm3/auth-for-gdm-*/database" "/var/lib/gdm3/.Xauthority"; do
        if [ -r "$auth_file" ]; then
            export XAUTHORITY="$auth_file"
            echo "$(date): Using XAUTHORITY: $XAUTHORITY" >> "$LOG_DIR/prelogin.log"
            break
        fi
    done
fi

# Set DISPLAY if not set
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi

# Set Qt environment
QT_SITE_PACKAGES=$(find "$APP_DIR/venv/lib/" -type d -name "site-packages" | head -n 1)
if [ -n "$QT_SITE_PACKAGES" ]; then
    QT_BASE_PATH="$QT_SITE_PACKAGES/PyQt6/Qt6"
    export QT_PLUGIN_PATH="${QT_BASE_PATH}/plugins"
    export LD_LIBRARY_PATH="${QT_BASE_PATH}/lib:${LD_LIBRARY_PATH}"
    export QT_QPA_PLATFORM="xcb"
fi

echo "$(date): Starting Fatih Client in pre-login mode..." >> "$LOG_DIR/prelogin.log"
echo "  DISPLAY=$DISPLAY" >> "$LOG_DIR/prelogin.log"
echo "  XAUTHORITY=$XAUTHORITY" >> "$LOG_DIR/prelogin.log"

# Run the client in pre-login mode
cd "$APP_DIR" || exit 1
"$VENV_PYTHON" "$APP_DIR/client.py" --prelogin >> "$LOG_DIR/prelogin.out.log" 2>> "$LOG_DIR/prelogin.err.log"

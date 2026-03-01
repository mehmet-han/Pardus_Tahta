#!/bin/bash

# --- Fatih Client Launcher and Watchdog Script (v5.0 - Multi-display support) ---

APP_DIR="/opt/fatih-client"
cd "$APP_DIR" || exit 1

# --- Properly Set X11 Environment Variables ---
# Detect active X display for current user
CURRENT_USER=$(whoami)

# Check if DISPLAY is already set
if [ -z "$DISPLAY" ]; then
    # Try to find user's X display from /tmp/.X11-unix
    for socket in /tmp/.X11-unix/X*; do
        if [ -S "$socket" ]; then
            DISPLAY_NUM="${socket##*/tmp/.X11-unix/X}"
            SOCKET_OWNER=$(stat -c '%U' "$socket" 2>/dev/null)
            if [ "$SOCKET_OWNER" = "$CURRENT_USER" ]; then
                export DISPLAY=":$DISPLAY_NUM"
                break
            fi
        fi
    done
    # loginctl ile aktif X oturumunu ara
    if [ -z "$DISPLAY" ]; then
        for sess in $(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}'); do
            SESS_USER=$(loginctl show-session "$sess" -p Name --value 2>/dev/null)
            SESS_TYPE=$(loginctl show-session "$sess" -p Type --value 2>/dev/null)
            SESS_DISPLAY=$(loginctl show-session "$sess" -p Display --value 2>/dev/null)
            if [ "$SESS_USER" = "$CURRENT_USER" ] && [ "$SESS_TYPE" = "x11" ] && [ -n "$SESS_DISPLAY" ]; then
                export DISPLAY="$SESS_DISPLAY"
                break
            fi
        done
    fi
    # Hâlâ bulunamadıysa ilk X socket'i kullan (GDM ile Debian-gdm sahibi olabilir)
    if [ -z "$DISPLAY" ]; then
        for socket in /tmp/.X11-unix/X*; do
            if [ -S "$socket" ]; then
                DISPLAY_NUM="${socket##*/tmp/.X11-unix/X}"
                export DISPLAY=":$DISPLAY_NUM"
                break
            fi
        done
    fi
    # Son çare
    [ -z "$DISPLAY" ] && export DISPLAY=:0
fi

# Set XAUTHORITY
if [ -z "$XAUTHORITY" ]; then
    # Try GDM location first (for GDM3 systems)
    GDM_AUTH="/run/user/$(id -u)/gdm/Xauthority"
    if [ -r "$GDM_AUTH" ]; then
        export XAUTHORITY="$GDM_AUTH"
    elif [ -r "$HOME/.Xauthority" ]; then
        export XAUTHORITY="$HOME/.Xauthority"
    fi
fi

# --- Set Qt Environment Variables ---
VENV_PYTHON="$APP_DIR/venv/bin/python"

LOG_DIR="$APP_DIR/logs"
mkdir -p "$LOG_DIR"

# Use system Qt libraries (for Pardus 19 compatibility)
# Don't override QT_PLUGIN_PATH - let it use system plugins
unset QT_PLUGIN_PATH
export QT_QPA_PLATFORM="xcb"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Log the environment for debugging
echo "$(date): Starting with environment:" >> "$LOG_DIR/watchdog.log"
echo "  DISPLAY=$DISPLAY" >> "$LOG_DIR/watchdog.log"
echo "  XAUTHORITY=$XAUTHORITY" >> "$LOG_DIR/watchdog.log"
echo "  QT_QPA_PLATFORM=$QT_QPA_PLATFORM" >> "$LOG_DIR/watchdog.log"

# --- Skip if running as fatih-kiosk (kiosk mode handles itself) ---
if [ "$(whoami)" = "fatih-kiosk" ]; then
    echo "$(date): Running as fatih-kiosk, skipping normal mode watchdog." >> "$LOG_DIR/watchdog.log"
    exit 0
fi

# --- Check if normal mode is already running (exclude --kiosk instances) ---
if pgrep -f "$VENV_PYTHON $APP_DIR/client.py$" >/dev/null; then
    echo "$(date): Fatih client (normal mode) is already running." >> "$LOG_DIR/watchdog.log"
    exit 0
fi

# --- Start in background by default ---
if [ "$1" = "--foreground" ] || [ "$1" = "-f" ]; then
    echo "Starting Fatih client watchdog in foreground..."
    # --- Main Watchdog Loop (Foreground) ---
    while true; do
      if ! pgrep -f "$VENV_PYTHON $APP_DIR/client.py$" >/dev/null; then
        echo "$(date): Fatih client not running. Starting it now..." >> "$LOG_DIR/watchdog.log"
        "$VENV_PYTHON" "$APP_DIR/client.py" >> "$LOG_DIR/client.out.log" 2>> "$LOG_DIR/client.err.log" &
      fi
      sleep 10
    done
else
    echo "$(date): Starting Fatih client watchdog in background..." >> "$LOG_DIR/watchdog.log"
    # Start the watchdog loop in background
    (
        while true; do
          if ! pgrep -f "$VENV_PYTHON $APP_DIR/client.py$" >/dev/null; then
            echo "$(date): Fatih client not running. Starting it now..." >> "$LOG_DIR/watchdog.log"
            "$VENV_PYTHON" "$APP_DIR/client.py" >> "$LOG_DIR/client.out.log" 2>> "$LOG_DIR/client.err.log" &
          fi
          sleep 10
        done
    ) &
    WATCHDOG_PID=$!
    echo "$(date): Watchdog started with PID: $WATCHDOG_PID" >> "$LOG_DIR/watchdog.log"
    # Detach from terminal
    disown $WATCHDOG_PID
fi

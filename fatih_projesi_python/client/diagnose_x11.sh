#!/bin/bash

echo "=== Fatih Client X11 Diagnostic ==="
echo ""

echo "Current user: $(whoami)"
echo "SUDO_USER: ${SUDO_USER:-not set}"
echo "HOME: $HOME"
echo ""

echo "=== X11 Environment ===" 
echo "DISPLAY: ${DISPLAY:-not set}"
echo "XAUTHORITY: ${XAUTHORITY:-not set}"
echo ""

if [ -f "$HOME/.Xauthority" ]; then
    echo "✓ .Xauthority file exists at: $HOME/.Xauthority"
    ls -la "$HOME/.Xauthority"
else
    echo "✗ .Xauthority file NOT found at: $HOME/.Xauthority"
fi
echo ""

echo "=== X Server Connection ==="
if xhost >/dev/null 2>&1; then
    echo "✓ Can connect to X server"
    xhost
else
    echo "✗ Cannot connect to X server"
    xhost 2>&1
fi
echo ""

echo "=== Qt Environment ==="
APP_DIR="/opt/fatih-client"
if [ -d "$APP_DIR/venv" ]; then
    echo "✓ Virtual environment exists"
    QT_SITE_PACKAGES=$(find "$APP_DIR/venv/lib/" -type d -name "site-packages" | head -n 1)
    if [ -n "$QT_SITE_PACKAGES" ]; then
        echo "✓ site-packages found: $QT_SITE_PACKAGES"
        if [ -d "$QT_SITE_PACKAGES/PyQt6" ]; then
            echo "✓ PyQt6 installed"
        else
            echo "✗ PyQt6 NOT installed"
        fi
    else
        echo "✗ site-packages NOT found"
    fi
else
    echo "✗ Virtual environment NOT found"
fi
echo ""

echo "=== Running Processes ==="
if pgrep -f "python.*client.py" >/dev/null; then
    echo "✓ Client is running:"
    ps aux | grep "[p]ython.*client.py"
else
    echo "✗ Client is NOT running"
fi
echo ""

echo "=== Recent Errors ==="
if [ -f "/opt/fatih-client/logs/client.err.log" ]; then
    echo "Last 10 lines of error log:"
    tail -10 /opt/fatih-client/logs/client.err.log
else
    echo "No error log found"
fi
echo ""

echo "=== Diagnostic Complete ==="

#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "--- Fatih Server Installer ---"

# --- IMPORTANT ---
# This script can be run from any directory
# It uses the current user and detects the server directory automatically
SERVER_USER=${SUDO_USER:-$USER}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo "Installing service for user: $SERVER_USER"
echo "Project directory: $PROJECT_DIR"

# 1. Detect system paths and generate service file dynamically
echo "Detecting system paths and generating service file..."

# Detect uvicorn path automatically
UVICORN_PATH=$(which uvicorn 2>/dev/null)
if [ -z "$UVICORN_PATH" ]; then
    echo "ERROR: uvicorn not found in PATH. Please install it first:"
    echo "  pip install uvicorn fastapi python-multipart"
    echo "  or"
    echo "  conda install uvicorn fastapi python-multipart"
    exit 1
fi

echo "Found uvicorn at: $UVICORN_PATH"

# Create a temporary service file with correct paths
TEMP_SERVICE_FILE="/tmp/fatih-server.service.tmp"
cat > "$TEMP_SERVICE_FILE" << EOF
[Unit]
Description=Fatih Projesi Control Server
After=network.target

[Service]
Type=simple
User=$SERVER_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$UVICORN_PATH app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Generated service file with paths:"
echo "  User: $SERVER_USER"
echo "  WorkingDirectory: $PROJECT_DIR"
echo "  ExecStart: $UVICORN_PATH"


# 2. Install and enable the service
echo "Installing systemd service..."
cp "$TEMP_SERVICE_FILE" /etc/systemd/system/fatih-server.service
chmod 644 /etc/systemd/system/fatih-server.service
systemctl daemon-reload
systemctl enable fatih-server.service
systemctl start fatih-server.service

# Clean up temporary file
rm -f "$TEMP_SERVICE_FILE"

echo "--- Installation Complete ---"
echo "You can now start the server with: sudo systemctl start fatih-server.service"
echo "It will start automatically on boot."
echo ""
echo "Service configuration:"
echo "  User: $SERVER_USER"
echo "  WorkingDirectory: $PROJECT_DIR"
echo "  ExecStart: $UVICORN_PATH"
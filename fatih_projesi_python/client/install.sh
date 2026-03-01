#!/bin/bash

# Exit immediately if a command fails.
set -e

# This script must be run as root.
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

echo "--- Fatih Client Installer (XDG Autostart Method) ---"

# 1. Define paths and detect the user who ran 'sudo'.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTUAL_USER=${SUDO_USER:-$(logname)}
APP_DIR="/opt/fatih-client"
VENV_DIR="$APP_DIR/venv"
AUTO_START_DIR="/etc/xdg/autostart"

echo "Installing for user: $ACTUAL_USER"
echo "Application will be installed in: $APP_DIR"

# 2. Add user to 'input' group for direct keyboard/mouse device access.
# This is required by the 'evdev' library to lock input without running as root.
# A reboot is required for this change to take effect.
echo "Adding user '$ACTUAL_USER' to the 'input' group..."
usermod -a -G input "$ACTUAL_USER"

# 3. Create application directories.
echo "Creating directories..."
mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/resources"
mkdir -p "$AUTO_START_DIR"

# 4. Install system dependencies.
echo "Updating package list and installing system dependencies..."
apt-get update
# libxcb-cursor0 can solve some Qt display issues on minimal systems.
# xauth is needed to handle X server authentication.
apt-get install -y python3 python3-pip python3-venv libxcb-cursor0 xauth

# 5. Create Python virtual environment and install dependencies from requirements.txt.
echo "Creating Python virtual environment in $VENV_DIR..."
python3 -m venv "$VENV_DIR"
# Use the venv's pip to install packages.
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements.txt"

# 6. Copy application files.
echo "Copying application files...from $SCRIPT_DIR to $APP_DIR"
cp "$SCRIPT_DIR/client.py" "$APP_DIR/"
cp "$SCRIPT_DIR/launch.sh" "$APP_DIR/"
cp "$SCRIPT_DIR/config.ini" "$APP_DIR/"
chmod +x "$APP_DIR/launch.sh"
# Copy resources if the directory exists, ignore errors if it doesn't.
cp -r "$SCRIPT_DIR/resources"/* "$APP_DIR/resources/" 2>/dev/null || true


# 8. Install the XDG Autostart file to run the client on user login.
echo "Installing XDG Autostart file..."
cp "$SCRIPT_DIR/fatih-client-autostart.desktop" "$AUTO_START_DIR/"
chmod 644 "$AUTO_START_DIR/fatih-client-autostart.desktop"

# 9. Set correct ownership for the application directory.
echo "Setting permissions for $APP_DIR..."
chown -R "$ACTUAL_USER":"$ACTUAL_USER" "$APP_DIR"

echo
echo "--- Installation Complete ---"
echo "IMPORTANT: A REBOOT IS REQUIRED for the new group permissions to take effect."
echo "Please REBOOT the client machine now."
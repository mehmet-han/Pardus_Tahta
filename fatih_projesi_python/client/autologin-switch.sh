#!/bin/bash

# Fatih Client - GDM AutomaticLogin Switch Helper
# Usage: autologin-switch.sh kiosk       -> Set auto-login to fatih-kiosk
#        autologin-switch.sh user [NAME] -> Set auto-login to specified user (default: ogretmen)
#        autologin-switch.sh disable     -> Disable auto-login
#
# Bu script sudo ile çalıştırılmalıdır.
# Sadece GDM config dosyalarını değiştirir, başka hiçbir şey yapmaz.

# GDM config dosyalarını belirle
GDM_CONFIGS=()
[ -f "/etc/gdm3/custom.conf" ] && GDM_CONFIGS+=("/etc/gdm3/custom.conf")
[ -f "/etc/gdm3/daemon.conf" ] && GDM_CONFIGS+=("/etc/gdm3/daemon.conf")
[ -f "/etc/gdm/custom.conf" ] && GDM_CONFIGS+=("/etc/gdm/custom.conf")
[ -f "/etc/gdm/daemon.conf" ] && GDM_CONFIGS+=("/etc/gdm/daemon.conf")

if [ ${#GDM_CONFIGS[@]} -eq 0 ]; then
    echo "ERROR: No GDM config files found"
    exit 1
fi

case "$1" in
    kiosk)
        TARGET_USER="fatih-kiosk"
        for f in "${GDM_CONFIGS[@]}"; do
            sed -i 's/^AutomaticLoginEnable = .*/AutomaticLoginEnable = true/' "$f"
            sed -i "s/^AutomaticLogin = .*/AutomaticLogin = $TARGET_USER/" "$f"
        done
        echo "Auto-login set to: $TARGET_USER"
        ;;
    user)
        TARGET_USER="${2:-ogretmen}"
        for f in "${GDM_CONFIGS[@]}"; do
            sed -i 's/^AutomaticLoginEnable = .*/AutomaticLoginEnable = true/' "$f"
            sed -i "s/^AutomaticLogin = .*/AutomaticLogin = $TARGET_USER/" "$f"
        done
        echo "Auto-login set to: $TARGET_USER"
        ;;
    disable)
        for f in "${GDM_CONFIGS[@]}"; do
            sed -i 's/^AutomaticLoginEnable = .*/AutomaticLoginEnable = false/' "$f"
        done
        echo "Auto-login disabled"
        ;;
    *)
        echo "Usage: $0 {kiosk|user [username]|disable}"
        exit 1
        ;;
esac

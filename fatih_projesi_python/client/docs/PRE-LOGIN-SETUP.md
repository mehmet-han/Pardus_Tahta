# Fatih Client Pre-Login Lock Screen Setup

This guide explains how to configure the Fatih client to run **BEFORE** the GDM3 login screen, preventing users from logging in until the Fatih lock is unlocked.

## Overview

The pre-login setup works as follows:

1. **System boots** → Fatih lock screen appears immediately
2. **Admin unlocks** → Lock screen disappears, GDM3 shows user selection
3. **User logs in** → Can choose from ogretmen, yetkili, or ogrenci accounts
4. **After login** → Normal Fatih client runs per-user (as configured in install.sh)

## Installation

### Step 1: Install Base Client First

Make sure the regular Fatih client is installed:

```bash
cd /home/cappittall/Documents/Fatih_Projesi/fatih_projesi_python/client
sudo ./install.sh
```

### Step 2: Run Pre-Login Installer

```bash
sudo ./install-prelogin.sh
```

This will:
- Create a dedicated `fatih-kiosk` user
- Configure GDM3 to auto-login to this user
- Set up a minimal kiosk session that shows only the Fatih lock screen
- Configure permissions for system restart

### Step 3: Make Scripts Executable

```bash
sudo chmod +x /opt/fatih-client/kiosk-launcher.sh
sudo chmod +x /opt/fatih-client/prelogin-launcher.sh
```

### Step 4: Reboot and Test

```bash
sudo reboot
```

After reboot:
1. You should see the Fatih lock screen immediately (black background, login button)
2. Click "Giriş" and enter admin password (default: `mebre`)
3. After unlock, GDM3 login screen appears with your 3 users
4. Login as normal

## Configuration

### Change Admin Password

Edit `/opt/fatih-client/config.ini`:

```ini
[General]
admin_password = your_new_password
```

### Disable Pre-Login Lock (Return to Normal Login)

Edit `/etc/gdm3/custom.conf`:

```ini
[daemon]
# Comment out or change to false:
# AutomaticLoginEnable = true
AutomaticLoginEnable = false
```

Then reboot.

### Re-Enable Pre-Login Lock

Edit `/etc/gdm3/custom.conf`:

```ini
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = fatih-kiosk
```

Then reboot.

## Troubleshooting

### Lock screen doesn't appear after boot

1. Check if fatih-kiosk user auto-login is enabled:
   ```bash
   cat /etc/gdm3/custom.conf | grep AutomaticLogin
   ```

2. Check kiosk logs:
   ```bash
   sudo cat /opt/fatih-client/logs/kiosk.log
   sudo cat /opt/fatih-client/logs/kiosk.err.log
   ```

3. Verify fatih-kiosk user exists:
   ```bash
   id fatih-kiosk
   ```

### Lock screen appears but won't unlock

1. Verify admin password in config:
   ```bash
   grep admin_password /opt/fatih-client/config.ini
   ```

2. Check kiosk logs for authentication errors:
   ```bash
   sudo tail -f /opt/fatih-client/logs/kiosk.log
   ```

### After unlock, login screen doesn't appear

1. Check if GDM3 restart permission is configured:
   ```bash
   sudo cat /etc/sudoers.d/fatih-kiosk
   ```

2. Manually restart GDM3 from another TTY (Ctrl+Alt+F2):
   ```bash
   sudo systemctl restart gdm3
   ```

### Want to bypass pre-login lock temporarily

From another TTY (Ctrl+Alt+F2):

```bash
# Disable auto-login temporarily
sudo sed -i 's/AutomaticLoginEnable = true/AutomaticLoginEnable = false/' /etc/gdm3/custom.conf
sudo systemctl restart gdm3
```

## Files Created

- `/etc/gdm3/custom.conf` - GDM3 auto-login configuration
- `/home/fatih-kiosk/.config/autostart/fatih-kiosk.desktop` - Kiosk autostart
- `/opt/fatih-client/kiosk-launcher.sh` - Kiosk mode launcher
- `/etc/sudoers.d/fatih-kiosk` - Sudo permissions for GDM3 restart

## Security Notes

1. The `fatih-kiosk` user has minimal permissions
2. Only admin password can unlock the pre-login screen
3. The kiosk user can only restart GDM3 (no other sudo access)
4. Keyboard input is blocked during lock (except for the unlock dialog)

## Uninstallation

To remove pre-login lock and return to normal:

```bash
# 1. Disable auto-login
sudo sed -i 's/AutomaticLoginEnable = true/AutomaticLoginEnable = false/' /etc/gdm3/custom.conf

# 2. Remove kiosk user
sudo userdel -r fatih-kiosk

# 3. Remove sudo permissions
sudo rm /etc/sudoers.d/fatih-kiosk

# 4. Reboot
sudo reboot
```

The per-user Fatih client will continue to work normally after each user logs in.

# Fatih Client X11 Authentication Fix

## Problem
After installing Fatih Client on Pardus, the application fails to start with errors:
```
Invalid MIT-MAGIC-COOKIE-1 key
qt.qpa.xcb: could not connect to display :0
Could not load the Qt platform plugin "xcb"
```

## Root Cause
The application starts via autostart but cannot access the X11 display because:
1. Missing or incorrect XAUTHORITY environment variable
2. No delay to ensure X server is ready before starting
3. Unreliable temporary file approach for environment variables

## Solution
This package contains fixed versions of the launcher scripts and an automated fix script.

## Files Included

1. **fix_x11_auth.sh** - Automated fix script (run this first)
2. **launch.sh** - Updated launcher with proper X11 environment handling  
3. **fatih-client-autostart.desktop** - Updated autostart configuration
4. **diagnose_x11.sh** - Diagnostic tool to check your setup
5. **README.md** - This file

## Quick Fix (Recommended)

```bash
# 1. Copy the fix script to your system
sudo cp fix_x11_auth.sh /tmp/
sudo chmod +x /tmp/fix_x11_auth.sh

# 2. Run the fix
sudo /tmp/fix_x11_auth.sh

# 3. Reboot or log out and log back in
sudo reboot
```

## What the Fix Does

The automated fix script will:
- ✅ Update `/opt/fatih-client/launch.sh` with proper X11 environment handling
- ✅ Update `/etc/xdg/autostart/fatih-client-autostart.desktop` with 5-second delay
- ✅ Clean up old temporary files
- ✅ Stop running instances
- ✅ Fix file permissions
- ✅ Configure X11 access

## Manual Testing

To test if the fix worked without rebooting:

```bash
# Stop any running instances
sudo pkill -f client.py

# Run diagnostic to check environment
sudo -u etapadmin ./diagnose_x11.sh

# Test launch manually in foreground (to see errors immediately)
sudo -u etapadmin /opt/fatih-client/launch.sh --foreground
```

## Checking Logs

After the fix, monitor the logs:

```bash
# Watch the main watchdog log
tail -f /opt/fatih-client/logs/watchdog.log

# Watch for errors
tail -f /opt/fatih-client/logs/client.err.log

# Watch output
tail -f /opt/fatih-client/logs/client.out.log
```

## What Changed

### launch.sh Changes
- Properly sets `DISPLAY=:0` if not set
- Sets `XAUTHORITY=$HOME/.Xauthority` with multiple fallback locations
- Logs environment variables for debugging
- More robust error handling

### Autostart Changes  
- Added 5-second delay before starting (`sleep 5`)
- Added `X-GNOME-Autostart-Delay=5` for additional safety
- Simplified execution command
- Removed dependency on temporary files

## Troubleshooting

### If it still doesn't work after the fix:

1. **Check X11 authority file exists:**
   ```bash
   ls -la ~/.Xauthority
   ```

2. **Allow local X connections:**
   ```bash
   xhost +local:
   ```

3. **Regenerate .Xauthority if needed:**
   ```bash
   touch ~/.Xauthority
   xauth generate :0 . trusted
   ```

4. **Check the user is in the input group:**
   ```bash
   groups etapadmin
   # Should include "input"
   ```

5. **Reinstall xcb library:**
   ```bash
   sudo apt-get install --reinstall libxcb-cursor0
   ```

### Common Error Messages

**"Invalid MIT-MAGIC-COOKIE-1 key"**
- Fix: XAUTHORITY variable not set correctly
- Solution: The fix script handles this

**"could not connect to display :0"**
- Fix: DISPLAY variable not set or X server not accessible
- Solution: Ensure X server is running and DISPLAY=:0

**"Could not load the Qt platform plugin 'xcb'"**
- Fix: Missing Qt libraries or plugin path not set
- Solution: Reinstall libxcb-cursor0 or check Qt installation

## Support

If problems persist:

1. Run the diagnostic script and save output:
   ```bash
   sudo -u etapadmin ./diagnose_x11.sh > diagnostic_output.txt
   ```

2. Check all log files in `/opt/fatih-client/logs/`

3. Try running manually to see real-time errors:
   ```bash
   sudo -u etapadmin /opt/fatih-client/launch.sh --foreground
   ```

## Manual Installation (Alternative)

If you prefer to apply changes manually instead of using the fix script:

1. **Update launch.sh:**
   ```bash
   sudo cp launch.sh /opt/fatih-client/launch.sh
   sudo chmod +x /opt/fatih-client/launch.sh
   ```

2. **Update autostart file:**
   ```bash
   sudo cp fatih-client-autostart.desktop /etc/xdg/autostart/
   sudo chmod 644 /etc/xdg/autostart/fatih-client-autostart.desktop
   ```

3. **Fix permissions:**
   ```bash
   sudo chown -R etapadmin:etapadmin /opt/fatih-client
   ```

4. **Reboot**

## Verification

After applying the fix and rebooting:

1. The application should start automatically
2. Check logs show no X11 errors:
   ```bash
   tail -20 /opt/fatih-client/logs/client.err.log
   ```
3. Process should be running:
   ```bash
   ps aux | grep client.py
   ```

## Technical Details

The fix works by:
1. Setting X11 environment variables (`DISPLAY`, `XAUTHORITY`) correctly
2. Searching multiple locations for `.Xauthority` file
3. Adding startup delays to ensure X server is ready
4. Logging environment for debugging
5. Running with proper user permissions

---

**Version:** 4.0  
**Date:** 2025-10-29  
**Tested on:** Pardus 19

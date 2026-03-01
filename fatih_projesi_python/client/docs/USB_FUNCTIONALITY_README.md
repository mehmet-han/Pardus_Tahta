# USB Auto-Lock Functionality

This document explains the USB-based screen locking functionality implemented in the Fatih Client Python version, which mirrors the behavior of the original C# implementation with enhanced logic.

## Overview

The system automatically locks the screen when the computer starts up. To unlock it, a USB drive containing a specific password file (`pass.txt`) must be inserted. **The system now intelligently tracks how it was unlocked and only locks back on USB removal if it was originally unlocked by that specific USB drive.**

## Key Improvement: Smart USB Locking

### Previous Behavior (Basic)
- USB insertion → Unlock
- USB removal → Always lock (regardless of unlock method)

### New Behavior (Smart)
- USB insertion → Unlock + Set "unlocked_by_usb" flag
- USB removal → Only lock if "unlocked_by_usb" flag is true
- Server unlock → Reset "unlocked_by_usb" flag
- Other unlock methods → Reset "unlocked_by_usb" flag

## How It Works

### 1. System Startup
- When the computer starts, the system automatically locks the screen
- Keyboard and mouse input are blocked
- The system shows a full-screen lock interface

### 2. USB Unlock Process
- Insert a USB drive containing a file named `pass.txt`
- The file must contain the exact password: `32541kehİUFali_veli_hüseyin?İ44EHEJSTRİHTEMES5488965E8GİEİ`
- The system automatically detects the USB drive and unlocks
- **Sets the "unlocked_by_usb" flag to true**
- Keyboard and mouse input are restored
- The lock screen disappears

### 3. Smart USB Removal Detection
- The system continuously monitors for USB drive removal
- **Only locks the system if the "unlocked_by_usb" flag is true**
- If the system was unlocked by other means (server, admin, etc.), USB removal won't lock it
- This prevents unwanted locking when USB is removed after server-side unlock

### 4. Server/Admin Unlock Handling
- When the system is unlocked by server commands or admin actions
- The "unlocked_by_usb" flag is automatically reset to false
- This ensures USB removal won't interfere with server-controlled unlocks

### 5. Additional USB Commands
- **Remove System**: Create a file named `rmove.txt` on a USB drive with the content: `uege32541kehİUFali_veli_hüseyin?İEHEJSTRİH52874TEMES548965E8GİEİ`
- This will trigger the system removal process

## Scenarios and Expected Behavior

### Scenario 1: USB Unlock → USB Remove
1. System starts locked
2. USB with password inserted → System unlocks
3. USB removed → System locks back ✅
4. **Reason**: System was unlocked by USB, so USB removal triggers re-lock

### Scenario 2: Server Unlock → USB Remove
1. System starts locked
2. Server sends unlock command → System unlocks
3. USB removed → System stays unlocked ✅
4. **Reason**: System was NOT unlocked by USB, so USB removal has no effect

### Scenario 3: USB Unlock → Server Lock → USB Remove
1. System starts locked
2. USB with password inserted → System unlocks
3. Server sends lock command → System locks
4. USB removed → System stays locked ✅
5. **Reason**: USB flag was reset when server locked the system

## Technical Implementation

### Key Functions

#### `check_usb_password()`
- Equivalent to C# `AcKapa()` function
- Scans mounted filesystems for USB drives
- Checks for `pass.txt` file with correct password
- Returns `True` if valid USB is found, `False` otherwise

#### `check_usb_remove()`
- Equivalent to C# `Rsystm()` function
- Scans for USB drives with `rmove.txt` file
- Triggers system removal if found

#### `check_usb_status()`
- Equivalent to C# `CheckInternetWork()` function
- Runs every 3 seconds to check USB status
- **Only locks system if it was originally unlocked by USB**

### USB Monitoring with Smart Logic

The system uses multiple monitoring approaches with enhanced state tracking:

1. **Udev Monitor**: Real-time USB device insertion/removal detection
2. **Periodic Timer**: Every 3 seconds, checks if USB with password is still present
3. **State Tracking**: Maintains state of USB presence AND unlock method
4. **Smart Locking**: Only locks on USB removal if system was unlocked by USB

### Key Variables

```python
class UdevMonitor:
    unlocked_by_usb = False  # Tracks if system was unlocked by USB
    
    def reset_usb_unlock_flag(self):
        # Called when system is unlocked by other means
        self.unlocked_by_usb = False
```

## File Structure

```
USB Drive/
├── pass.txt          # Contains unlock password
└── rmove.txt        # Contains system removal command (optional)
```

## Configuration

The USB passwords are defined as constants in the code:

```python
USB_PASSWORD = "32541kehİUFali_veli_hüseyin?İ44EHEJSTRİHTEMES5488965E8GİEİ"
USB_REMOVE_PASSWORD = "uege32541kehİUFali_veli_hüseyin?İEHEJSTRİH52874TEMES548965E8GİEİ"
```

## Testing

Use the provided test script to verify USB functionality:

```bash
python3 test_usb_functionality.py
```

This script can:
1. Create test files for testing
2. Run continuous USB detection monitoring
3. **Test the new USB unlock logic and scenarios**

## Security Features

- **Input Blocking**: When locked, all keyboard and mouse input is blocked
- **Full-Screen Lock**: Lock screen covers the entire display
- **Automatic Detection**: No manual intervention required for lock/unlock
- **Password Verification**: Exact password match required for unlock
- **Smart Locking**: USB removal only affects system if USB was responsible for unlock

## Compatibility

This implementation is designed to work on Linux systems and provides the same functionality as the original C# Windows application, **plus the enhanced smart locking behavior**. The system automatically adapts to different USB drive types and mount points.

## Troubleshooting

### Common Issues

1. **USB not detected**: Ensure the USB drive is properly mounted and contains the correct `pass.txt` file
2. **System not unlocking**: Verify the password in `pass.txt` matches exactly
3. **System not locking on removal**: Check that the USB drive was properly unmounted AND the system was unlocked by that USB
4. **System locks unexpectedly**: Check if the system was unlocked by USB (check logs for "unlocked_by_usb" messages)

### Logs

The system logs all USB-related activities to `~/fatih_client.log`. Check this file for debugging information, especially:
- "USB unlock key found!" - USB detected
- "USB unlock flag reset" - System unlocked by other means
- "USB drive that unlocked the system was removed" - Smart locking triggered
- "USB drive removed but system was not unlocked by USB" - Smart locking not triggered

## Dependencies

- `pyudev`: USB device monitoring
- `evdev`: Input device control
- `PyQt6`: GUI framework
- Standard Linux system utilities

## Notes

- The system requires root privileges for input device control
- USB detection works with any removable storage device (USB drives, SD cards, etc.)
- The system automatically handles different filesystem types
- Password checking is case-sensitive and requires exact match
- **The new smart locking prevents interference between USB and server-based unlock methods**

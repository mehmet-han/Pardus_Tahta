# Fatih Client Bug Fixes

## Bug #1: USB Unlock Loop (FIXED)

### Problem
When a USB key unlocked the system during a scheduled lock period, the client would enter an infinite loop:
1. USB unlocks → manual_override = True
2. Schedule check → respects manual_override, skips lock
3. **BUG:** Schedule check immediately resets manual_override = False
4. Next schedule check → manual_override is False → locks system
5. USB periodic check → sees locked + USB present → unlocks again
6. **LOOP repeats indefinitely**

### Root Cause
In `check_schedule()` method, line 1327 was unconditionally resetting `manual_override = False` at the end of every lock period check, even when the override was actively preventing a lock.

### Fix
**File:** `client.py:1327`

**Before:**
```python
else:
    # It's time to be locked.
    if not self.is_locked:
        if self.manual_override:
            logging.info("Schedule says lock, but manual override is active. Skipping lock.")
        else:
            self.lock_system("Zamanlanmış kilitleme")

    # BUG: This resets override even when we just respected it!
    self.manual_override = False
```

**After:**
```python
else:
    # It's time to be locked.
    if not self.is_locked:
        if self.manual_override:
            logging.info("Schedule says lock, but manual override is active. Skipping lock.")
            # Keep manual_override active until the next scheduled unlock period
        else:
            self.lock_system("Zamanlanmış kilitleme")
    # manual_override only resets when schedule unlocks (line 1315)
```

### Testing
1. Configure a schedule with lock period (e.g., after 5pm)
2. During lock period, plug in USB key
3. System should unlock and stay unlocked
4. USB key should remain active without causing lock/unlock loops

---

## Bug #2: Schedule AttributeError (FIXED)

### Problem
Client crashed on startup with:
```python
AttributeError: 'list' object has no attribute 'get'
```

### Root Cause
Server returns schedule as a 3D list `[day][period][property]`, but client code expected a dictionary and tried to use `.get()` method.

### Fix
**File:** `client.py:1240-1301`

Updated `check_schedule()` to detect and handle both list and dictionary formats:

```python
hours_data = self.schedule['hours']

# Handle both list and dict structures
if isinstance(hours_data, list):
    # Server returns hours as a 3D list: [day][period][property]
    if day_of_week < len(hours_data):
        day_schedule = hours_data[day_of_week]
        for period_idx in range(1, min(19, len(day_schedule))):
            period_data = day_schedule[period_idx]
            if isinstance(period_data, list) and len(period_data) >= 3:
                start_time = period_data[1]
                end_time = period_data[2]
                # ... check time logic
elif isinstance(hours_data, dict):
    # Handle dictionary format for backward compatibility
    # ... existing dict logic
```

### Testing
1. Start client with server running
2. Client should load schedule without crashes
3. Check logs for schedule parsing success

---

## Bug #3: SSL Warnings Spam (FIXED)

### Problem
Error log filled with repeated SSL warnings:
```
InsecureRequestWarning: Unverified HTTPS request is being made to host 'api.mebre.com.tr'
```

### Root Cause
Client uses `verify=False` for SSL (testing environment) but didn't suppress urllib3 warnings.

### Fix
**File:** `client.py:10,21`

Added import and warning suppression:

```python
import urllib3

# Disable SSL warnings since we're using verify=False for testing
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
```

### Testing
Check error logs - should be clean except for actual errors.

---

## Bug #4: Lock Screen Not Showing at Startup (FIXED)

### Problem
After reboot, client process was running but lock screen window wasn't visible.

### Root Cause
Client initialized with `self.is_locked = True`, but never called `lock_system()` which shows the window. The `lock_system()` method only runs when `not self.is_locked`, so it was skipped.

### Fix
**File:** `client.py:1001,1026`

Changed initialization sequence:

```python
def __init__(self):
    super().__init__()
    self.is_locked = False  # Start as unlocked
    # ... other init ...
    self.init_ui()
    self.init_network_timer()
    # ... other timers ...

    # Show the lock screen at startup
    self.lock_system("Sistem başlangıcı")

    self.poll_server()
```

### Testing
1. Reboot system
2. Client should start and immediately show full-screen lock
3. Login button should be visible and functional

---

## Summary of Changed Files

1. **client.py**
   - Line 10: Added `import urllib3`
   - Line 21: Added `urllib3.disable_warnings()`
   - Line 1001: Changed `self.is_locked = True` to `False`
   - Line 1026: Added `self.lock_system("Sistem başlangıcı")`
   - Lines 1240-1301: Updated `check_schedule()` to handle list format
   - Line 1327: Removed unconditional `manual_override = False` reset
   - Lines 1792-1936: Added kiosk mode support

## Deployment

After pulling these fixes:

```bash
# On remote machine
cd /home/etapadmin/Fatih_Projesi
git pull

# Stop current client
pkill -f client.py

# Copy updated client
sudo cp fatih_projesi_python/client/client.py /opt/fatih-client/

# Watchdog will auto-restart within 10 seconds
# Or manually start:
sudo -u etapadmin /opt/fatih-client/launch.sh --foreground
```

All bugs should be resolved after restart!

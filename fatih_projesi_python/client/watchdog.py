#!/usr/bin/env python3
"""
Watchdog/Guardian Service for Fatih Client
C# ConfigServices/Service1.cs karşılığı

Görevleri:
1. Ana uygulamanın çalışıp çalışmadığını kontrol eder
2. Çalışmıyorsa otomatik yeniden başlatır
3. Autostart dosyasını düzenli kontrol edip silinmişse geri oluşturur
4. Systemd servisi olarak çalışır
"""

import os
import sys
import time
import logging
import subprocess
import shutil

# --- Configuration ---
APP_NAME = "fatih-client"
APP_EXECUTABLE = "/opt/fatih-client/client.py"
AUTOSTART_DIR = "/etc/xdg/autostart"
AUTOSTART_FILE = os.path.join(AUTOSTART_DIR, "fatih-client-autostart.desktop")
LOG_FILE = "/var/log/fatih-watchdog.log"
CHECK_INTERVAL = 10  # seconds

# Autostart içeriği
AUTOSTART_CONTENT = """[Desktop Entry]
Type=Application
Name=Fatih Client
Comment=Akıllı Tahta Kilit Sistemi
Exec=/usr/bin/python3 /opt/fatih-client/client.py
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=false
"""

# Systemd servis dosyası yolu
SYSTEMD_SERVICE = "/etc/systemd/system/fatih-client.service"

# --- Logging ---
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)


def is_process_running(process_name: str) -> bool:
    """Check if a process with the given name is running."""
    try:
        result = subprocess.run(
            ['pgrep', '-f', process_name],
            capture_output=True, text=True, timeout=5
        )
        return result.returncode == 0
    except Exception:
        return False


def start_application():
    """Start the main Fatih Client application."""
    try:
        if os.path.exists(APP_EXECUTABLE):
            logging.info(f"Starting {APP_EXECUTABLE}...")
            subprocess.Popen(
                ['/usr/bin/python3', APP_EXECUTABLE],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )
            logging.info("Application started successfully")
        else:
            logging.error(f"Application not found: {APP_EXECUTABLE}")
    except Exception as e:
        logging.error(f"Failed to start application: {e}")


def repair_autostart():
    """Check and repair the autostart .desktop file."""
    try:
        if not os.path.exists(AUTOSTART_FILE):
            logging.warning(f"Autostart file missing: {AUTOSTART_FILE}")
            os.makedirs(AUTOSTART_DIR, exist_ok=True)
            with open(AUTOSTART_FILE, 'w') as f:
                f.write(AUTOSTART_CONTENT)
            logging.info(f"Autostart file restored: {AUTOSTART_FILE}")
        else:
            # İçerik doğru mu kontrol et
            with open(AUTOSTART_FILE, 'r') as f:
                content = f.read()
            if APP_EXECUTABLE not in content:
                logging.warning("Autostart file content is incorrect, restoring...")
                with open(AUTOSTART_FILE, 'w') as f:
                    f.write(AUTOSTART_CONTENT)
                logging.info("Autostart file content restored")
    except PermissionError:
        logging.error("Permission denied when repairing autostart file")
    except Exception as e:
        logging.error(f"Error repairing autostart: {e}")


def check_systemd_service():
    """Ensure the systemd service is enabled."""
    try:
        result = subprocess.run(
            ['systemctl', 'is-enabled', 'fatih-client.service'],
            capture_output=True, text=True, timeout=5
        )
        if result.stdout.strip() != 'enabled':
            logging.warning("Fatih client service is not enabled, enabling...")
            subprocess.run(
                ['sudo', 'systemctl', 'enable', 'fatih-client.service'],
                capture_output=True, timeout=5
            )
            logging.info("Service enabled")
    except Exception as e:
        logging.error(f"Error checking systemd service: {e}")


def main():
    """Main watchdog loop."""
    logging.info("=== Fatih Watchdog Starting ===")
    
    cycle_count = 0
    while True:
        try:
            cycle_count += 1
            
            # 1. Ana uygulamanın çalışıp çalışmadığını kontrol et
            if not is_process_running('client.py'):
                logging.warning("Fatih Client is not running! Restarting...")
                start_application()
                time.sleep(5)  # Wait for the app to start
            
            # 2. Her 6 döngüde (60 saniye) autostart dosyasını kontrol et
            if cycle_count % 6 == 0:
                repair_autostart()
            
            # 3. Her 30 döngüde (5 dakika) systemd servisini kontrol et
            if cycle_count % 30 == 0:
                check_systemd_service()
                cycle_count = 0
            
            time.sleep(CHECK_INTERVAL)
            
        except KeyboardInterrupt:
            logging.info("Watchdog stopped by user")
            break
        except Exception as e:
            logging.error(f"Watchdog error: {e}")
            time.sleep(CHECK_INTERVAL)


if __name__ == '__main__':
    main()

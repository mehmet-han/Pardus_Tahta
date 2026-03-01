import sys
import os
import time
import requests
import threading
import configparser
import logging
import random
import shutil
import urllib3
from PyQt5.QtWidgets import (QApplication, QMainWindow, QLabel, QPushButton, QLineEdit,
                           QVBoxLayout, QHBoxLayout, QWidget, QDialog, QGridLayout,
                           QMenu, QSystemTrayIcon, QTextEdit, QMessageBox, QStyle, QComboBox, QAction)
from PyQt5.QtGui import QPixmap, QScreen, QFont, QIcon, QCursor
from PyQt5.QtCore import Qt, QTimer, pyqtSignal, QObject, QPoint
from evdev import InputDevice, ecodes, list_devices
from pyudev import Context, Monitor
from datetime import datetime

# Disable SSL warnings since we're using verify=False for testing
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# --- NEW: Setup Logging ---
log_file = os.path.expanduser("~/fatih_client.log")
logging.basicConfig(filename=log_file, level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')
logging.info("--- Fatih Client Starting Up ---")

# --- Configuration ---
# Define paths for user-specific and default configurations
APP_NAME = "fatih-client"
APP_INSTALL_DIR = "/opt/fatih-client"
USER_CONFIG_DIR = os.path.expanduser(f"~/.config/{APP_NAME}")
USER_CONFIG_PATH = os.path.join(USER_CONFIG_DIR, "config.ini")

# Resources path (for background images, etc.)
RESOURCES_DIR = os.path.join(APP_INSTALL_DIR, "resources")
if not os.path.exists(RESOURCES_DIR):
    # Fallback for local testing
    RESOURCES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "resources")

# The default config is installed system-wide, but we need a fallback for local testing
DEFAULT_CONFIG_PATH = "/opt/fatih-client/config.ini"
if not os.path.exists(DEFAULT_CONFIG_PATH):
    DEFAULT_CONFIG_PATH = "config.ini" # Fallback for local testing

def setup_configuration():
    """
    Ensures user configuration exists, copying from default if necessary.
    Returns the path to the active configuration file.
    """
    if not os.path.exists(USER_CONFIG_PATH):
        logging.info(f"User config not found at {USER_CONFIG_PATH}. Creating from default.")
        try:
            os.makedirs(USER_CONFIG_DIR, exist_ok=True)
            # Check if default exists before copying
            if os.path.exists(DEFAULT_CONFIG_PATH):
                shutil.copy(DEFAULT_CONFIG_PATH, USER_CONFIG_PATH)
                logging.info(f"Copied default config to {USER_CONFIG_PATH}")
            else:
                logging.error(f"Default config not found at {DEFAULT_CONFIG_PATH}. Cannot create user config.")
                # If default is missing, we can't proceed with creating a user config.
                # The app will likely fail later, which is appropriate.
                return DEFAULT_CONFIG_PATH # Fallback to trying to read the (missing) default
        except Exception as e:
            logging.error(f"Could not create user configuration: {e}")
            # Fallback to default config path if user config cannot be created
            return DEFAULT_CONFIG_PATH
    return USER_CONFIG_PATH

# Set the global CONFIG_PATH to the user's writable config file
CONFIG_PATH = setup_configuration()

config = configparser.ConfigParser()
config.read(CONFIG_PATH)
SETTINGS = config['settings']

# --- NEW: Configuration Validation ---
def validate_config():
    """Validate that all required configuration variables are present"""
    required_vars = [
        'api_url', 'wb_user', 'wb_pass', 'user_agent', 
        'corporate_code', 'board_id', 'version', 'sub_version'
    ]
    
    missing_vars = []
    for var in required_vars:
        if var not in SETTINGS:
            missing_vars.append(var)
    
    if missing_vars:
        error_msg = f"Missing required configuration variables: {', '.join(missing_vars)}"
        logging.error(error_msg)
        raise ValueError(error_msg)
    
    logging.info("Configuration validation passed")
    logging.info(f"Loaded configuration for board: {SETTINGS.get('board_id')}")
    logging.info(f"API URL: {SETTINGS.get('api_url')}")
    logging.info(f"Version: {SETTINGS.get('version')}.{SETTINGS.get('sub_version')}")

# Validate configuration on startup
try:
    validate_config()
except ValueError as e:
    print(f"Configuration Error: {e}")
    sys.exit(1)

# --- NEW: USB Password Constants (matching C# code) ---
USB_PASSWORD = "32541kehİUFali_veli_hüseyin?İ44EHEJSTRİHTEMES5488965E8GİEİ"
USB_REMOVE_PASSWORD = "uege32541kehİUFali_veli_hüseyin?İEHEJSTRİH52874TEMES548965E8GİEİ"

# --- Dynamic Password Control (from C# pctrl.cs) ---
# Sunucu ve istemci aynı algoritma ile şifre üretiyor
# Öğretmen Mebrecep uygulamasından bu şifreyi görüp giriyor

def get_network_time():
    """
    NTP sunucusundan ağ zamanını al (C# Tools.GetNetworkTime() karşılığı)
    Şifre hesaplaması için doğru zaman kritik
    """
    import socket
    import struct
    
    ntp_servers = SETTINGS.get('ntp_servers', 'time.google.com,time.windows.com').split(',')
    
    for server in ntp_servers:
        try:
            server = server.strip()
            # NTP packet
            client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            client.settimeout(3)
            
            # NTP request packet (48 bytes, first byte = 0x1B for client mode)
            data = b'\x1b' + 47 * b'\0'
            client.sendto(data, (server, 123))
            
            msg, _ = client.recvfrom(1024)
            client.close()
            
            # Unpack timestamp (bytes 40-43 = seconds since 1900)
            unpacked = struct.unpack('!12I', msg)
            t = unpacked[10] - 2208988800  # Convert from 1900 to 1970 epoch
            
            network_time = datetime.fromtimestamp(t)
            logging.debug(f"Got network time from {server}: {network_time}")
            return network_time
            
        except Exception as e:
            logging.debug(f"Failed to get time from {server}: {e}")
            continue
    
    # Fallback to local time if all NTP servers fail
    logging.warning("Could not get network time, using local time")
    return datetime.now()

def generate_dynamic_password(dt: datetime, minute_offset: int = 0) -> str:
    """
    Dinamik şifre üret (C# pctrl.ps() karşılığı)
    Formül: (Year * Day * Minute * 85) ilk 6 karakteri
    
    Args:
        dt: Tarih/saat
        minute_offset: Dakika toleransı (0, 1, veya 2)
    """
    try:
        year = dt.year
        day = dt.day
        minute = dt.minute
        
        # C# kodundaki gibi: minute 0 veya 1 ise 2 yap
        if minute == 0 or minute == 1:
            minute = 2
        
        minute += minute_offset
        
        # Hesaplama: Year * Day * Minute * 85
        result = year * day * minute * 85
        
        # İlk 6 karakteri al
        password = str(result)[:6]
        logging.debug(f"Generated password for {dt} (offset={minute_offset}): {password}")
        return password
        
    except Exception as e:
        logging.error(f"Error generating dynamic password: {e}")
        return "000000"

def validate_dynamic_password(entered_password: str) -> bool:
    """
    Girilen şifreyi doğrula (C# pctrl.pc() karşılığı)
    Anlık dakika, +1 ve +2 dakika toleransı ile kontrol eder
    
    Args:
        entered_password: Kullanıcının girdiği şifre
    
    Returns:
        True eğer şifre geçerli ise
    """
    try:
        # Önce ağ zamanını dene, başarısızsa local time kullan
        current_time = get_network_time()
        
        # 3 farklı dakika offset ile kontrol et (tolerans)
        for offset in [0, 1, 2]:
            expected_password = generate_dynamic_password(current_time, offset)
            if entered_password == expected_password:
                logging.info(f"Password validated with offset={offset}")
                return True
        
        # Eğer ağ zamanı ile eşleşmediyse, local time ile de kontrol et
        # (internet olmadığında cihaz saati ile çalışabilsin)
        local_time = datetime.now()
        if local_time != current_time:
            logging.info("Trying local time for password validation...")
            for offset in [0, 1, 2]:
                expected_password = generate_dynamic_password(local_time, offset)
                if entered_password == expected_password:
                    logging.info(f"Password validated with local time, offset={offset}")
                    return True
        
        logging.warning(f"Invalid password entered")
        return False
        
    except Exception as e:
        logging.error(f"Error validating password: {e}")
        # Son çare: local time ile kontrol et
        try:
            local_time = datetime.now()
            for offset in [0, 1, 2]:
                expected_password = generate_dynamic_password(local_time, offset)
                if entered_password == expected_password:
                    logging.info(f"Password validated with local time (fallback), offset={offset}")
                    return True
        except:
            pass
        return False

# --- Generate User-Key like C# Tools.userKey() ---
# Key oluşturma kurum koduna bağlı yapıldı
def generate_user_key(corporate_code: str = None) -> str:
    """Generate a unique key based on corporate code (kurum kodu)"""
    if corporate_code is None:
        corporate_code = SETTINGS.get('corporate_code', '0')
    
    charset = "a?A)b(B*cCdD-eEf+FgGhHi[IjJkKm?MlLm]MnNoOpPrRs)StT1*23[456-7890"
    # Seed the random generator with corporate code for consistent keys per institution
    seed_value = sum(ord(c) for c in str(corporate_code))
    rng = random.Random(seed_value)
    part1 = ''.join(rng.choice(charset[0:len(charset)-1]) for _ in range(5))
    part2 = ''.join(rng.choice(charset[1:len(charset)-1]) for _ in range(4))
    part3 = ''.join(rng.choice(charset[2:len(charset)-1]) for _ in range(8))
    part4 = ''.join(rng.choice(charset[3:len(charset)-1]) for _ in range(8))
    return f"{part1}_{part2}_{part3}!{part4}"

# --- NEW: USB Check Function (equivalent to C# AcKapa) ---
def check_usb_password() -> bool:
    """
    Check if USB drive with correct password is present.
    Equivalent to C# AcKapa() function.
    """
    try:
        # Get all mounted filesystems
        with open('/proc/mounts', 'r') as f:
            mounts = f.readlines()
        
        for mount in mounts:
            parts = mount.split()
            if len(parts) >= 2:
                device = parts[0]
                mount_point = parts[1]
                
                # Skip non-USB mount points (tmp, system directories)
                if mount_point.startswith('/tmp') or mount_point.startswith('/sys') or mount_point.startswith('/proc'):
                    continue
                
                # Check if it's a removable device (USB drive) - typically mounted under /media or /mnt
                if device.startswith('/dev/sd') or device.startswith('/dev/usb'):
                    # Additional check: USB drives are usually mounted in /media or /mnt
                    if not (mount_point.startswith('/media') or mount_point.startswith('/mnt') or mount_point.startswith('/run/media')):
                        continue
                        
                    pass_file = os.path.join(mount_point, "pass.txt")
                    if os.path.exists(pass_file):
                        try:
                            with open(pass_file, 'r') as f:
                                content = f.read().strip()
                                if content == USB_PASSWORD:
                                    logging.info(f"USB password found at {mount_point}")
                                    return True
                        except Exception as e:
                            logging.warning(f"Error reading pass.txt from {mount_point}: {e}")
                            continue
        
        logging.debug("No USB drive with correct password found")
        return False
        
    except Exception as e:
        logging.error(f"Error checking USB password: {e}")
        return False

# --- NEW: USB Remove Check Function (equivalent to C# Rsystm) ---
def check_usb_remove() -> bool:
    """
    Check if USB drive with remove command is present.
    Equivalent to C# Rsystm() function.
    """
    try:
        with open('/proc/mounts', 'r') as f:
            mounts = f.readlines()
        
        for mount in mounts:
            parts = mount.split()
            if len(parts) >= 2:
                device = parts[0]
                mount_point = parts[1]
                
                # Skip non-USB mount points
                if mount_point.startswith('/tmp') or mount_point.startswith('/sys') or mount_point.startswith('/proc'):
                    continue
                
                if device.startswith('/dev/sd') or device.startswith('/dev/usb'):
                    # USB drives are usually mounted in /media or /mnt
                    if not (mount_point.startswith('/media') or mount_point.startswith('/mnt') or mount_point.startswith('/run/media')):
                        continue
                        
                    remove_file = os.path.join(mount_point, "rmove.txt")
                    if os.path.exists(remove_file):
                        try:
                            with open(remove_file, 'r') as f:
                                content = f.read().strip()
                                if content == USB_REMOVE_PASSWORD:
                                    logging.info(f"USB remove command found at {mount_point}")
                                    return True
                        except Exception as e:
                            logging.warning(f"Error reading rmove.txt from {mount_point}: {e}")
                            continue
        
        return False
        
    except Exception as e:
        logging.error(f"Error checking USB remove: {e}")
        return False

# --- On-Screen Keyboard Dialog (equivalent to C# FormEkranKlavyesi) ---
class OnScreenKeyboard(QDialog):
    def __init__(self, target_field=None):
        super().__init__()
        self.target_field = target_field
        self.shift_pressed = False
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("Ekran Klavyesi")
        self.setModal(True)
        self.setWindowFlags(Qt.WindowStaysOnTopHint)

        layout = QVBoxLayout()

        # Keyboard layout
        keyboard_layout = QGridLayout()

        # Row 1: Numbers 1-0
        numbers = "1234567890"
        for i, char in enumerate(numbers):
            btn = QPushButton(char)
            btn.clicked.connect(lambda checked, c=char: self.add_char(c))
            keyboard_layout.addWidget(btn, 0, i)

        # Row 2: QWERTYUIOP
        qwerty1 = "qwertyuiop"
        for i, char in enumerate(qwerty1):
            btn = QPushButton(char.upper() if self.shift_pressed else char)
            btn.clicked.connect(lambda checked, c=char: self.add_char(c))
            keyboard_layout.addWidget(btn, 1, i)

        # Row 3: ASDFGHJKL
        qwerty2 = "asdfghjkl"
        for i, char in enumerate(qwerty2):
            btn = QPushButton(char.upper() if self.shift_pressed else char)
            btn.clicked.connect(lambda checked, c=char: self.add_char(c))
            keyboard_layout.addWidget(btn, 2, i)

        # Row 4: ZXCVBNM and special keys
        qwerty3 = "zxcvbnm"
        for i, char in enumerate(qwerty3):
            btn = QPushButton(char.upper() if self.shift_pressed else char)
            btn.clicked.connect(lambda checked, c=char: self.add_char(c))
            keyboard_layout.addWidget(btn, 3, i)

        # Special keys
        shift_btn = QPushButton("⇧ Shift")
        shift_btn.clicked.connect(self.toggle_shift)
        keyboard_layout.addWidget(shift_btn, 3, 7)

        # NEW: Add a Tab button
        tab_btn = QPushButton("⇥ Tab")
        tab_btn.clicked.connect(self.press_tab)
        keyboard_layout.addWidget(tab_btn, 3, 8)

        backspace_btn = QPushButton("⌫")
        backspace_btn.clicked.connect(self.backspace)
        keyboard_layout.addWidget(backspace_btn, 3, 9)

        # Row 5: Space and Enter
        space_btn = QPushButton("Space")
        space_btn.clicked.connect(lambda: self.add_char(" "))
        keyboard_layout.addWidget(space_btn, 4, 0, 1, 7)

        enter_btn = QPushButton("Enter")
        enter_btn.clicked.connect(self.enter_text)
        keyboard_layout.addWidget(enter_btn, 4, 7, 1, 3)

        layout.addLayout(keyboard_layout)

        # Control buttons
        control_layout = QHBoxLayout()
        clear_btn = QPushButton("Temizle")
        clear_btn.clicked.connect(self.clear_text)
        control_layout.addWidget(clear_btn)

        close_btn = QPushButton("Kapat")
        close_btn.clicked.connect(self.accept)
        control_layout.addWidget(close_btn)

        layout.addLayout(control_layout)
        self.setLayout(layout)

    def add_char(self, char):
        if not self.target_field: return
        current = self.target_field.text()
        if self.shift_pressed:
            char = char.upper()
        self.target_field.setText(current + char)
        if self.shift_pressed:
            self.shift_pressed = False
            self.update_keyboard_case()

    def press_tab(self):
        """NEW: Move focus to the next input field."""
        if not self.target_field: return
        # Find the parent window and ask it to move focus to the next widget
        parent = self.target_field.parentWidget()
        if parent:
            parent.focusNextChild()

    def toggle_shift(self):
        self.shift_pressed = not self.shift_pressed
        self.update_keyboard_case()

    def update_keyboard_case(self):
        # Update all letter buttons
        for btn in self.findChildren(QPushButton):
            text = btn.text()
            if len(text) == 1 and text.isalpha():
                if self.shift_pressed:
                    btn.setText(text.upper())
                else:
                    btn.setText(text.lower())

    def backspace(self):
        if not self.target_field: return
        current = self.target_field.text()
        self.target_field.setText(current[:-1])

    def clear_text(self):
        if not self.target_field: return
        self.target_field.clear()

    def enter_text(self):
        if self.target_field:
            # In a real app, this might submit a form
            self.accept()

# --- NEW: LineEdit that opens the keyboard on click ---
class KeyboardLineEdit(QLineEdit):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._keyboard = None
        self._just_closed = False

    def mousePressEvent(self, event):
        super().mousePressEvent(event)
        
        if self._just_closed:
            return

        if self._keyboard is None or not self._keyboard.isVisible():
            self._keyboard = OnScreenKeyboard(target_field=self)
            
            if self.parent():
                parent_pos = self.parent().mapToGlobal(QPoint(0,0))
                pos = self.mapToGlobal(QPoint(0, self.height()))
                screen_geometry = QApplication.primaryScreen().geometry()
                keyboard_size = self._keyboard.sizeHint()
                if pos.x() + keyboard_size.width() > screen_geometry.width():
                    pos.setX(screen_geometry.width() - keyboard_size.width())
                if pos.y() + keyboard_size.height() > screen_geometry.height():
                    pos.setY(parent_pos.y() - keyboard_size.height())
                self._keyboard.move(pos)
            
            self._keyboard.exec()
            
            # Set a flag to prevent immediate reopening and reset it after a short delay
            self._just_closed = True
            QTimer.singleShot(100, self._reset_flag)

    def _reset_flag(self):
        self._just_closed = False

# --- Login Dialog ---
class LoginDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(None)
        self.parent = parent
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("Sistem Girişi")
        self.setModal(True)
        self.setWindowFlags(Qt.WindowStaysOnTopHint)
        logging.info("LoginDialog UI initialized")

        layout = QVBoxLayout()

        # Title
        title = QLabel("Yönetici Girişi")
        title.setFont(QFont("Arial", 16, QFont.Weight.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)

        # Password field
        self.password_field = KeyboardLineEdit()
        self.password_field.setEchoMode(QLineEdit.EchoMode.Password)
        self.password_field.setPlaceholderText("Mebrecep den şifre yazınız")
        self.password_field.setFont(QFont("Arial", 14))
        layout.addWidget(self.password_field)

        # Buttons
        button_layout = QHBoxLayout()

        cancel_btn = QPushButton("İptal")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)

        login_btn = QPushButton("Giriş")
        login_btn.clicked.connect(self.attempt_login)
        login_btn.setDefault(True)
        button_layout.addWidget(login_btn)

        layout.addLayout(button_layout)
        self.setLayout(layout)

    def attempt_login(self):
        password = self.password_field.text()
        logging.info(f"Login attempt with password: {'*' * len(password)}")
        
        if self.parent.validate_admin_password(password):
            logging.info("Password validated successfully")
            # NEW: Immediately notify the server that the board is unlocked
            self.parent.acknowledge_command("tahtaLock", "0")
            self.parent.save_log("Admin şifre ile giriş yapıldı", "login")
            self.parent.unlock_system("Admin şifre ile açıldı")
            self.accept()
        else:
            logging.warning("Invalid password entered")
            QMessageBox.warning(self, "Hata", "Geçersiz şifre!")
            self.password_field.clear()

# --- Board Configuration Dialog ---
class BoardConfigDialog(QDialog):
    def __init__(self, parent=None, network_client=None):
        super().__init__(None)
        self.parent = parent
        self.network_client = network_client
        self.boards = []
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("Tahta Yapılandırması")
        self.setModal(True)
        self.setWindowFlags(Qt.WindowStaysOnTopHint)

        layout = QVBoxLayout()

        # Title
        title = QLabel("Tahta Yapılandırması")
        title.setFont(QFont("Arial", 16, QFont.Weight.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)

        # Corporate code input - maskelenmiş görünsün (**** şeklinde)
        corporate_layout = QHBoxLayout()
        corporate_layout.addWidget(QLabel("Kurum Kodu:"))
        self.corporate_code_field = KeyboardLineEdit()
        self.corporate_code_field.setEchoMode(QLineEdit.EchoMode.Password)  # **** şeklinde görünsün
        self.corporate_code_field.setText(SETTINGS.get('corporate_code', ''))
        corporate_layout.addWidget(self.corporate_code_field)
        layout.addLayout(corporate_layout)

        # Password input - admin şifresi zorunlu
        password_layout = QHBoxLayout()
        password_layout.addWidget(QLabel("Şifre:"))
        self.password_field = KeyboardLineEdit()
        self.password_field.setEchoMode(QLineEdit.EchoMode.Password)
        self.password_field.setPlaceholderText("Admin şifresini giriniz")
        password_layout.addWidget(self.password_field)
        layout.addLayout(password_layout)

        # Fetch boards button
        self.fetch_btn = QPushButton("Tahtaları Getir")
        self.fetch_btn.clicked.connect(self.fetch_boards)
        layout.addWidget(self.fetch_btn)

        # Board selection
        board_layout = QHBoxLayout()
        board_layout.addWidget(QLabel("Tahta Seçin:"))
        self.board_combo = QComboBox()
        self.board_combo.setEnabled(False)
        board_layout.addWidget(self.board_combo)
        layout.addLayout(board_layout)

        # Buttons
        button_layout = QHBoxLayout()

        cancel_btn = QPushButton("İptal")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)

        confirm_btn = QPushButton("Onayla")
        confirm_btn.clicked.connect(self.confirm_selection)
        confirm_btn.setDefault(True)
        button_layout.addWidget(confirm_btn)

        layout.addLayout(button_layout)
        self.setLayout(layout)

    def fetch_boards(self):
        corporate_code = self.corporate_code_field.text().strip()
        if not corporate_code:
            QMessageBox.warning(self, "Hata", "Kurum kodu gerekli!")
            return

        # Şifre zorunlu kontrolü
        password = self.password_field.text().strip()
        if not password:
            QMessageBox.warning(self, "Hata", "Şifre gerekli! Lütfen admin şifrenizi giriniz.")
            return

        # Şifre doğrulama - config'deki admin_password ile kontrol et
        config_password = SETTINGS.get('admin_password', 'mebre')
        if password != config_password:
            QMessageBox.warning(self, "Hata", "Şifre yanlış!")
            return

        # İlk kurulumda şifre değiştirilmemiş ise uyarı ver
        password_changed = SETTINGS.get('password_changed', 'false').lower() == 'true'
        if not password_changed:
            QMessageBox.warning(self, "Şifre Değişikliği Gerekli",
                "İlk kurulumda varsayılan şifre kullanılmaktadır.\n"
                "Güvenliğiniz için lütfen önce şifrenizi değiştiriniz.\n\n"
                "Sağ tık menüsünden 'Şifre Değiştir' seçeneğini kullanınız.")
            return

        if not self.network_client:
            QMessageBox.critical(self, "Hata", "Network client başlatılamadı!")
            return

        # Temporarily update the network client's settings for this request
        original_code = self.network_client.settings.get('corporate_code')
        self.network_client.settings['corporate_code'] = corporate_code
        
        try:
            items = self.network_client.get_values()
            # Restore original corporate code after request
            self.network_client.settings['corporate_code'] = original_code

            if items is not None:
                if items and len(items) > 0:
                    self.boards = items
                    self.board_combo.clear()
                    for board in items:
                        board_name = board.get('Name', f'Tahta {board.get("id", "N/A")}')
                        self.board_combo.addItem(f'{board.get("id", "N/A")} - {board_name}',
                                               board.get("id"))
                    self.board_combo.setEnabled(True)
                    QMessageBox.information(self, "Başarılı", f"{len(items)} tahta bulundu.")
                else:
                    QMessageBox.warning(self, "Uyarı", "Bu kurum için tahta bulunamadı.")
            else:
                QMessageBox.warning(self, "Hata", "Sunucudan tahta listesi alınamadı.")
        except Exception as e:
            # Restore original code in case of error
            self.network_client.settings['corporate_code'] = original_code
            QMessageBox.warning(self, "Hata", f"Bir hata oluştu: {e}")

    def confirm_selection(self):
        if not self.board_combo.isEnabled():
            QMessageBox.warning(self, "Hata", "Önce tahtaları getirin!")
            return

        selected_board_id = self.board_combo.currentData()
        if selected_board_id is None:
            QMessageBox.warning(self, "Hata", "Tahta seçin!")
            return

        # Update configuration
        config = configparser.ConfigParser()
        config.read(CONFIG_PATH)
        config.set('settings', 'corporate_code', self.corporate_code_field.text().strip())
        config.set('settings', 'board_id', str(selected_board_id))

        # Find board name
        board_name = "Unknown Board"
        for board in self.boards:
            if board.get("id") == selected_board_id:
                board_name = board.get("Name", f"Tahta {selected_board_id}")
                break
        config.set('settings', 'board_name', board_name)

        try:
            with open(CONFIG_PATH, 'w') as configfile:
                config.write(configfile)

            # Sistem geneline de yaz (kiosk mode için - fatih-kiosk kullanıcısı buradan okur)
            system_config_path = "/opt/fatih-client/config.ini"
            try:
                sys_config = configparser.ConfigParser()
                sys_config.read(system_config_path)
                if 'settings' not in sys_config:
                    sys_config.add_section('settings')
                sys_config.set('settings', 'corporate_code', self.corporate_code_field.text().strip())
                sys_config.set('settings', 'board_id', str(selected_board_id))
                sys_config.set('settings', 'board_name', board_name)
                with open(system_config_path, 'w') as f:
                    sys_config.write(f)
                logging.info(f"System-wide config updated at {system_config_path}")
            except Exception as e:
                logging.warning(f"Could not update system-wide config: {e}")
                # Sistem config güncellenemezse bile devam et

            # Kiosk kullanıcısının config'ini de güncelle (varsa)
            kiosk_config_path = "/home/fatih-kiosk/.config/fatih-client/config.ini"
            try:
                kiosk_dir = os.path.dirname(kiosk_config_path)
                os.makedirs(kiosk_dir, exist_ok=True)
                kiosk_config = configparser.ConfigParser()
                kiosk_config.read(system_config_path)  # Sistem config'ini baz al
                kiosk_config.set('settings', 'corporate_code', self.corporate_code_field.text().strip())
                kiosk_config.set('settings', 'board_id', str(selected_board_id))
                kiosk_config.set('settings', 'board_name', board_name)
                with open(kiosk_config_path, 'w') as f:
                    kiosk_config.write(f)
                logging.info(f"Kiosk user config updated at {kiosk_config_path}")
            except Exception as e:
                logging.warning(f"Could not update kiosk user config: {e}")

            # Update current SETTINGS in memory
            SETTINGS['corporate_code'] = self.corporate_code_field.text().strip()
            SETTINGS['board_id'] = str(selected_board_id)
            SETTINGS['board_name'] = board_name

            # Update board ID display on main window
            if self.parent:
                self.parent.update_board_id_display()

            QMessageBox.information(self, "Başarılı",
                                  f"Tahta yapılandırması güncellendi:\nID: {selected_board_id}\nAd: {board_name}")
            self.accept()

        except PermissionError:
            QMessageBox.critical(self, "İzin Hatası",
                                 f"Yapılandırma dosyası kaydedilemedi: '{CONFIG_PATH}'.\n"
                                 "Ayarları değiştirmek için lütfen uygulamayı yönetici olarak çalıştırın (örn. 'sudo').")
        except Exception as e:
            QMessageBox.warning(self, "Hata", f"Yapılandırma kaydedilemedi: {e}")


# --- Change Password Dialog ---
class ChangePasswordDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(None)
        self.parent = parent
        self.init_ui()

    def init_ui(self):
        self.setWindowTitle("Şifre Değiştir")
        self.setModal(True)
        self.setWindowFlags(Qt.WindowStaysOnTopHint)

        layout = QVBoxLayout()

        # Title
        title = QLabel("Admin Şifresini Değiştir")
        title.setFont(QFont("Arial", 16, QFont.Weight.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)

        # Current password
        current_layout = QHBoxLayout()
        current_layout.addWidget(QLabel("Mevcut Şifre:"))
        self.current_field = KeyboardLineEdit()
        self.current_field.setEchoMode(QLineEdit.EchoMode.Password)
        current_layout.addWidget(self.current_field)
        layout.addLayout(current_layout)

        # New password
        new_layout = QHBoxLayout()
        new_layout.addWidget(QLabel("Yeni Şifre:"))
        self.new_field = KeyboardLineEdit()
        self.new_field.setEchoMode(QLineEdit.EchoMode.Password)
        new_layout.addWidget(self.new_field)
        layout.addLayout(new_layout)

        # Confirm password
        confirm_layout = QHBoxLayout()
        confirm_layout.addWidget(QLabel("Yeni Şifre (Tekrar):"))
        self.confirm_field = KeyboardLineEdit()
        self.confirm_field.setEchoMode(QLineEdit.EchoMode.Password)
        confirm_layout.addWidget(self.confirm_field)
        layout.addLayout(confirm_layout)

        # Buttons
        button_layout = QHBoxLayout()

        cancel_btn = QPushButton("İptal")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)

        change_btn = QPushButton("Değiştir")
        change_btn.clicked.connect(self.change_password)
        change_btn.setDefault(True)
        button_layout.addWidget(change_btn)

        layout.addLayout(button_layout)
        self.setLayout(layout)

    def change_password(self):
        current = self.current_field.text()
        new = self.new_field.text()
        confirm = self.confirm_field.text()

        if not current or not new or not confirm:
            QMessageBox.warning(self, "Hata", "Tüm alanları doldurun!")
            return

        # Mevcut şifre doğrulama - config'deki admin_password ile kontrol et
        config_password = SETTINGS.get('admin_password', 'mebre')
        if current != config_password:
            QMessageBox.warning(self, "Hata", "Mevcut şifre yanlış!")
            return

        if new != confirm:
            QMessageBox.warning(self, "Hata", "Yeni şifreler eşleşmiyor!")
            return

        if len(new) < 4:
            QMessageBox.warning(self, "Hata", "Şifre en az 4 karakter olmalı!")
            return

        if new == 'mebre':
            QMessageBox.warning(self, "Hata", "Yeni şifre varsayılan şifre ile aynı olamaz!")
            return

        # Update configuration
        config = configparser.ConfigParser()
        config.read(CONFIG_PATH)
        config.set('settings', 'admin_password', new)
        config.set('settings', 'password_changed', 'true')

        try:
            with open(CONFIG_PATH, 'w') as configfile:
                config.write(configfile)

            # Sistem geneline de yaz (kiosk mode için)
            system_config_path = "/opt/fatih-client/config.ini"
            try:
                sys_config = configparser.ConfigParser()
                sys_config.read(system_config_path)
                if 'settings' not in sys_config:
                    sys_config.add_section('settings')
                sys_config.set('settings', 'admin_password', new)
                sys_config.set('settings', 'password_changed', 'true')
                with open(system_config_path, 'w') as f:
                    sys_config.write(f)
                logging.info(f"System-wide config password updated at {system_config_path}")
            except Exception as e:
                logging.warning(f"Could not update system-wide config password: {e}")

            # Kiosk kullanıcısının config'ini de güncelle
            kiosk_config_path = "/home/fatih-kiosk/.config/fatih-client/config.ini"
            try:
                kiosk_config = configparser.ConfigParser()
                kiosk_config.read(kiosk_config_path)
                if 'settings' not in kiosk_config:
                    kiosk_config.add_section('settings')
                kiosk_config.set('settings', 'admin_password', new)
                kiosk_config.set('settings', 'password_changed', 'true')
                with open(kiosk_config_path, 'w') as f:
                    kiosk_config.write(f)
                logging.info(f"Kiosk config password updated at {kiosk_config_path}")
            except Exception as e:
                logging.warning(f"Could not update kiosk config password: {e}")

            # Update current SETTINGS
            SETTINGS['admin_password'] = new
            SETTINGS['password_changed'] = 'true'

            self.parent.save_log("Admin şifresi değiştirildi", "security")
            QMessageBox.information(self, "Başarılı", "Şifre başarıyla değiştirildi!")
            self.accept()

        except PermissionError:
            QMessageBox.critical(self, "İzin Hatası",
                                 f"Yapılandırma dosyası kaydedilemedi: '{CONFIG_PATH}'.\n"
                                 "Ayarları değiştirmek için lütfen uygulamayı yönetici olarak çalıştırın (örn. 'sudo').")
        except Exception as e:
            QMessageBox.warning(self, "Hata", f"Şifre kaydedilemedi: {e}")

# --- Keyboard Locker Thread (More Aggressive) ---
class KeyboardLocker(threading.Thread):
    def __init__(self):
        super().__init__()
        self.daemon = True
        self.devices = []
        self.stop_event = threading.Event()
        self._find_input_devices()

    def _find_input_devices(self):
        paths = list_devices()
        for path in paths:
            try:
                device = InputDevice(path)
                caps = device.capabilities()

                # Only grab keyboard devices, NOT mice
                # Check if device has keyboard-specific keys and lacks mouse buttons
                if ecodes.EV_KEY in caps:
                    has_keyboard_keys = any(key in caps.get(ecodes.EV_KEY, [])
                                          for key in [ecodes.KEY_A, ecodes.KEY_ENTER, ecodes.KEY_SPACE])
                    has_mouse_buttons = any(key in caps.get(ecodes.EV_KEY, [])
                                          for key in [ecodes.BTN_LEFT, ecodes.BTN_RIGHT, ecodes.BTN_MIDDLE])

                    # Only lock if it's a keyboard (has keyboard keys but no mouse buttons)
                    if has_keyboard_keys and not has_mouse_buttons:
                        logging.info(f"Found keyboard device to lock: {device.name} at {device.path}")
                        self.devices.append(device)
                    elif has_mouse_buttons:
                        logging.info(f"Skipping mouse device: {device.name} at {device.path}")
                    else:
                        logging.info(f"Skipping unknown input device: {device.name} at {device.path}")

            except Exception as e:
                logging.warning(f"Could not access device {path}: {e}")
                continue
        if not self.devices:
            logging.warning("No keyboard devices found by evdev.")

    def run(self):
        if not self.devices: return
        try:
            self.contexts = [dev.grab_context() for dev in self.devices]
            for context in self.contexts: context.__enter__()
            logging.info("Keyboard lock acquired on keyboard devices only (mice remain free).")
            self.stop_event.wait()
        except Exception as e:
            logging.error(f"Error grabbing devices: {e}.")
        finally:
            for context in getattr(self, 'contexts', []): context.__exit__(None, None, None)
            logging.info("Keyboard/mouse lock released.")

    def stop(self):
        self.stop_event.set()

# --- USB Monitor Thread (Enhanced for removal detection) ---
class UdevMonitor(QObject):
    usbUnlockSignal = pyqtSignal()
    usbRemoveSignal = pyqtSignal()
    usbRemovedSignal = pyqtSignal()  # NEW: Signal for when USB is removed
    
    def __init__(self):
        super().__init__()
        self.monitor_thread = threading.Thread(target=self._run, daemon=True)
        self.context = Context()
        self.monitor = Monitor.from_netlink(self.context)
        self.monitor.filter_by('block', 'partition')
        self.last_usb_state = False  # Track if USB was present in last check
        self.unlocked_by_usb = False  # NEW: Track if system was unlocked by USB
        
    def start(self): 
        self.monitor_thread.start()
        
    def _run(self):
        logging.info("USB monitor started.")
        for device in iter(self.monitor.poll, None):
            if device.action == 'add':
                time.sleep(2)  # Wait for mount
                self.check_device(device)
            elif device.action == 'remove':
                # NEW: Handle USB removal
                time.sleep(1)  # Wait for unmount
                self.check_usb_removal()
                
    def check_device(self, device):
        mount_point = self.get_mount_point(device)
        if not mount_point: return
        
        unlock_file = os.path.join(mount_point, "pass.txt")
        if os.path.exists(unlock_file):
            with open(unlock_file, 'r') as f: 
                content = f.read().strip()
            if content == USB_PASSWORD:
                logging.info("USB unlock key found!")
                self.last_usb_state = True
                self.unlocked_by_usb = True  # NEW: Mark that system was unlocked by USB
                self.usbUnlockSignal.emit()
                
        remove_file = os.path.join(mount_point, "rmove.txt")
        if os.path.exists(remove_file):
            with open(remove_file, 'r') as f: 
                content = f.read().strip()
            if content == USB_REMOVE_PASSWORD:
                logging.info("USB remove key found!")
                self.usbRemoveSignal.emit()
                
    def check_usb_removal(self):
        """
        NEW: Check if USB drive with password was removed
        Only lock if system was originally unlocked by USB
        """
        current_usb_state = check_usb_password()
        
        # If USB was present before but not now, check if we should lock
        if self.last_usb_state and not current_usb_state:
            if self.unlocked_by_usb:
                logging.info("USB drive that unlocked the system was removed - locking system")
                self.last_usb_state = False
                self.unlocked_by_usb = False  # Reset the flag
                self.usbRemovedSignal.emit()
            else:
                logging.info("USB drive removed but system was not unlocked by USB - not locking")
                self.last_usb_state = False
        elif not current_usb_state:
            self.last_usb_state = False
            
    def reset_usb_unlock_flag(self):
        """
        NEW: Reset the USB unlock flag when system is unlocked by other means
        """
        self.unlocked_by_usb = False
        logging.info("USB unlock flag reset - system unlocked by other means")
            
    def get_mount_point(self, device):
        try:
            with open('/proc/mounts', 'r') as f:
                for line in f:
                    if line.startswith(device.device_node): 
                        return line.split()[1]
        except Exception: 
            return None

# --- NEW: Network Client for Server Communication ---
class NetworkClient:
    """
    Handles all communication with the backend server, mirroring the
    functionality of the C# ClassClient.
    """
    def __init__(self, settings):
        self.settings = settings
        self.api_url = self.settings.get('api_url')
        self.auth = (self.settings.get('wb_user'), self.settings.get('wb_pass'))

    def _get_headers(self, core_code: str) -> dict:
        """Generates the required headers for an API request."""
        def cFnc_original(code_str: str) -> str:
            timestamp = str(time.time())
            s = f"{code_str}?{timestamp}"
            replacements = {
                "0":"!g", "1":"gt", "2":"_a", "3":"me", "4":"?b", 
                "5":"_z", "6":"fi", "7":"+d", "8":"da", "9":"|k",
                " ":"kz", ".":"?u", ":":"wa"
            }
            for old, new in replacements.items(): 
                s = s.replace(old, new)
            return s
            
        headers = {
            "User-Agent": self.settings.get('user_agent'), 
            "User-Key": generate_user_key(), 
            "UserCore": cFnc_original(core_code)
        }
        logging.debug(f"Request headers: {headers}")
        return headers

    def _make_request(self, core_code: str, data: dict, timeout: int = 5):
        """Makes a POST request to the server and returns the response."""
        if not self.check_network():
            logging.warning("Network is unavailable. Aborting request.")
            return None
        
        headers = self._get_headers(core_code)
        try:
            # IMPORTANT: Added verify=False to bypass SSL certificate verification.
            # This is a potential security risk and is for testing purposes.
            # If this resolves the connection issue, the server's SSL certificate
            # may need to be fixed or added to the system's trust store.
            response = requests.post(
                self.api_url, 
                headers=headers, 
                data=data,
                auth=self.auth, 
                timeout=timeout,
                verify=False
            )
            if response.status_code != 200:
                logging.error(f"API Error: {response.status_code} for {self.api_url} with data {data}. Response: {response.text[:200]}")
                return None
            return response
        except requests.exceptions.SSLError as e:
            logging.error(f"SSL Error during network request: {e}. This is likely due to an untrusted server certificate. Temporarily bypassing verification.")
            return None
        except requests.RequestException as e:
            logging.error(f"Network request failed: {e}")
            return None

    def check_network(self):
        """Check if network is available by connecting to a known host."""
        try:
            import socket
            socket.create_connection(("8.8.8.8", 53), timeout=3)
            return True
        except OSError:
            return False

    def ctrl_post(self):
        """
        Fetches control commands from the server.
        Equivalent to C# CtrlPost().
        """
        data = {
            "corporate_code": self.settings.get('corporate_code'),
            "fnc": "3480",
            "t_n": self.settings.get('board_id'),
            "t_na": self.settings.get('board_name', 'Pardus Board')
        }
        response = self._make_request("5567", data)
        return response.text if response else None

    def set_value(self, column, value):
        """
        Updates a specific value on the server.
        Equivalent to C# SetValue().
        """
        data = {
            "corporate_code": self.settings.get('corporate_code'), 
            "t_n": self.settings.get('board_id'), 
            "fnc": "3480", 
            "c_l": column, 
            "value": value
        }
        response = self._make_request("5566", data)
        if response:
            logging.info(f"Acknowledged command: set {column}={value}")
        return response is not None

    def save_log(self, log_name, vog_name):
        """
        Sends a log entry to the server.
        Equivalent to C# LogSave().
        """
        if vog_name == "logistek":
            self.log_request()

        data = {
            "corporate_code": self.settings.get('corporate_code'),
            "fnc": "3480",
            "t_n": self.settings.get('board_id'),
            "log": f"{self.settings.get('version')}-{self.settings.get('sub_version')}:{log_name}",
            "vog": vog_name
        }
        response = self._make_request("5571", data)
        if response:
            logging.info(f"Log saved: {vog_name} - {log_name}")
        return response is not None

    def log_request(self):
        """
        Sends a special log request.
        Equivalent to C# logRequest().
        """
        data = {
            "corporate_code": self.settings.get('corporate_code'),
            "fnc": "3480",
            "t_n": self.settings.get('board_id')
        }
        response = self._make_request("5574", data)
        if response:
            logging.info("Log request sent successfully.")
        return response is not None

    def get_values(self):
        """
        Retrieves board configurations/schedules.
        Equivalent to C# GetValues().
        """
        data = {
            "corporate_code": self.settings.get('corporate_code'),
            "fnc": "3480"
        }
        response = self._make_request("5563", data)
        if response:
            try:
                return response.json()
            except ValueError:
                logging.error(f"Failed to decode JSON from GetValues: {response.text}")
                return None
        return None

    def get_inspc(self, st, gn):
        """
        Gets inspection data.
        Equivalent to C# GetInspc().
        """
        data = {
            "corporate_code": self.settings.get('corporate_code'),
            "fnc": "3480",
            "t_n": self.settings.get('board_id'),
            "s_t": str(st),
            "g_n": str(gn)
        }
        response = self._make_request("5573", data)
        return response.text if response else ""

    def check_version(self):
        """
        Checks for a new client version.
        Equivalent to C# vck().
        """
        current_version = self.settings.get('version')
        data = {"fnc": "3480"}
        response = self._make_request("5570", data)
        if response and response.text:
            return response.text.strip()
        return current_version


# --- Main Application Window ---
class FatihClientApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.is_locked = False  # Start as unlocked, then lock_system() will show the screen
        self.keyboard_locker = None
        self.usb_check_timer = None
        # NEW: Instantiate the NetworkClient
        self.network_client = NetworkClient(SETTINGS)
        # Server command state
        self.shutDown = 0
        self.tahta_lock = 0
        self.system_remove = 0
        self.log_send = 0

        # --- SCHEDULING ---
        self.schedule = None
        self.manual_override = False # True if unlocked by user, ignores schedule until next lock time
        # C# kSaat[] karşılığı - çıkış saatlerinde tekrar kilitlemeyi önler
        self.exit_time_locked = [0] * 20  # index 1-18 kullanılacak (her ders periyodu için)
        self.last_schedule_day = -1  # Gün değişince exit_time_locked sıfırlanacak
        # --- END SCHEDULING ---

        self.init_ui()
        self.init_network_timer()
        self.init_usb_monitor()
        self.init_usb_check_timer()
        self.init_maintenance_timer()
        self.init_time_timer()
        self.init_schedule_timer() # New timer for scheduling

        # Show the lock screen at startup
        self.lock_system("Sistem başlangıcı")

        self.poll_server()

    def init_ui(self):
        # NEW: Visible change to confirm new version
        self.setWindowTitle("Fatih Client v1.5 - Scheduling Enabled")
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint)
        self.setGeometry(QApplication.primaryScreen().geometry())

        # Ensure the window accepts mouse events
        self.setMouseTracking(True)
        self.setFocusPolicy(Qt.FocusPolicy.StrongFocus)
        
        # Background image
        self.background = QLabel(self)
        bg_image_path = os.path.join(RESOURCES_DIR, "Artboard 3.png")
        if os.path.exists(bg_image_path):
            self.background.setPixmap(QPixmap(bg_image_path))
        else:
            # Fallback to solid color if image not found
            logging.warning(f"Background image not found: {bg_image_path}")
            self.background.setStyleSheet("background-color: #1a1a2e;")
        self.background.setScaledContents(True)
        self.background.setGeometry(self.rect())

        # Time display (bottom-right corner)
        self.time_label = QLabel("", self)
        self.time_label.setStyleSheet("color: white; font-size: 18px; background-color: rgba(0,0,0,0.7); padding: 5px;")
        self.time_label.setAlignment(Qt.AlignRight)
        self.time_label.setGeometry(self.width() - 250, self.height() - 50, 240, 40)

        # Board Name display (top-center) - TAHTA ADI üst ortada
        self.board_id_label = QLabel("", self)
        # Qt 5.11 uyumlu stylesheet - çok büyük padding
        self.board_id_label.setStyleSheet("""
            QLabel {
                color: white; 
                background-color: rgba(0, 0, 0, 220); 
                padding: 25px 40px;
                border-radius: 10px;
            }
        """)
        self.board_id_label.setFont(QFont('Sans', 20, QFont.Bold))
        self.board_id_label.setAlignment(Qt.AlignCenter)
        # Üst ortada - sabit boyut
        label_width = 450
        label_height = 100
        label_x = (self.width() - label_width) // 2  # Tam ortada
        self.board_id_label.setGeometry(label_x, 20, label_width, label_height)
        self.board_id_label.setMinimumHeight(label_height)
        self.update_board_id_display()

        # Status message label
        self.message_label = QLabel("Yükleniyor...", self)
        self.message_label.setStyleSheet("color: white; font-size: 32px; background-color: rgba(0,0,0,0.5);")
        self.message_label.setAlignment(Qt.AlignCenter)
        self.message_label.setWordWrap(True)
        self.message_label.setGeometry(50, self.height() // 2 - 100, self.width() - 100, 200)

        # Login button - TAHTAYI AÇ butonu
        self.login_button = QPushButton("TAHTAYI AÇ", self)
        self.login_button.setStyleSheet("background-color: #0066cc; color: white; border: 3px solid white; border-radius: 10px;")
        self.login_button.setFont(QFont('DejaVu Sans', 18))
        self.login_button.clicked.connect(self.show_login_dialog)
        # Sabit boyut ayarla
        button_width = 280
        button_height = 60
        self.login_button.setFixedSize(button_width, button_height)
        # Butonu ekranın ortasına konumlandır
        screen_center_x = self.width() // 2
        screen_center_y = self.height() // 2
        self.login_button.move(screen_center_x - button_width // 2, screen_center_y + 80)
        self.login_button.raise_()
        self.login_button.setVisible(True)
        self.login_button.show()

        logging.info(f"Login button positioned at: ({screen_center_x - button_width // 2}, {screen_center_y + 80})")
        print(f"Login button created and positioned at: ({screen_center_x - button_width // 2}, {screen_center_y + 80})")
        print(f"Login button visible: {self.login_button.isVisible()}")
        print(f"Login button enabled: {self.login_button.isEnabled()}")
        print(f"Button parent: {self.login_button.parent()}")
        print(f"Button window flags: {self.login_button.windowFlags()}")

        # Additional debugging - check window properties
        print(f"Window size: {self.size()}")
        print(f"Window is visible: {self.isVisible()}")
        print(f"Window is active: {self.isActiveWindow()}")

        # Admin command input (hidden)
        self.admin_input = QLineEdit(self)
        self.admin_input.setPlaceholderText("Admin komutları için Ctrl+K...")
        self.admin_input.setStyleSheet("background-color: rgba(0,0,0,0.3); color: white; border: 1px solid white;")
        self.admin_input.setGeometry(10, 10, 300, 30)
        self.admin_input.hide()
        self.admin_input.returnPressed.connect(self.process_admin_command)

        # Set up context menu
        self.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.customContextMenuRequested.connect(self.show_context_menu)

        # Initialize system tray
        self.init_system_tray()

    def init_system_tray(self):
        """Initialize system tray icon and menu"""
        try:
            self.tray_icon = QSystemTrayIcon(self)
            # Use a default icon if resources don't exist
            icon_path = "resources/tray_icon.png"
            if os.path.exists(icon_path):
                self.tray_icon.setIcon(QIcon(icon_path))
            else:
                # Create a simple icon
                self.tray_icon.setIcon(self.style().standardIcon(QStyle.StandardPixmap.SP_ComputerIcon))

            self.tray_icon.setToolTip("Fatih Akıllı Tahta")

            # Create tray menu
            tray_menu = QMenu()
            show_action = QAction("Göster", self)
            show_action.triggered.connect(self.show)
            tray_menu.addAction(show_action)

            hide_action = QAction("Gizle", self)
            hide_action.triggered.connect(self.hide)
            tray_menu.addAction(hide_action)

            tray_menu.addSeparator()

            exit_action = QAction("Çıkış", self)
            exit_action.triggered.connect(QApplication.quit)
            tray_menu.addAction(exit_action)

            self.tray_icon.setContextMenu(tray_menu)
            self.tray_icon.show()

            # Balloon tip
            self.tray_icon.showMessage(
                "Fatih Client",
                "Program çalışıyor ve sistem korunuyor.",
                QSystemTrayIcon.MessageIcon.Information,
                3000
            )

        except Exception as e:
            logging.error(f"System tray initialization failed: {e}")

    def init_network_timer(self):
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.poll_server)
        # Use configurable polling interval (default 5 seconds)
        polling_interval = int(SETTINGS.get('polling_interval', 5)) * 1000  # Convert to milliseconds
        self.timer.start(polling_interval)
        logging.info(f"Server polling timer started with {polling_interval/1000} second interval")

    def on_usb_unlock(self):
        """Handles the event of a USB unlock by logging and unlocking."""
        logging.info("USB unlock signal received.")
        self.save_log("USB anahtar ile giriş yapıldı", "login")
        self.unlock_system("USB ile açıldı")

    def init_usb_monitor(self):
        self.usb_monitor = UdevMonitor()
        self.usb_monitor.usbUnlockSignal.connect(self.on_usb_unlock)
        self.usb_monitor.usbRemoveSignal.connect(self.remove_system)
        self.usb_monitor.usbRemovedSignal.connect(lambda: self.lock_system("USB çıkarıldığı için kilitlendi"))  # NEW: Handle USB removal
        self.usb_monitor.start()
        
    def init_usb_check_timer(self):
        """
        NEW: Initialize timer for periodic USB checks (equivalent to C# CheckInternetWork)
        """
        self.usb_check_timer = QTimer(self)
        self.usb_check_timer.timeout.connect(self.check_usb_status)
        # This can be made configurable if needed
        usb_check_interval = int(SETTINGS.get('usb_check_interval', 3)) * 1000  # Convert to milliseconds
        self.usb_check_timer.start(usb_check_interval)
        logging.info(f"USB check timer started with {usb_check_interval/1000} second interval")

    def init_maintenance_timer(self):
        """
        NEW: Initialize timer for maintenance tasks (GetValues, version check, etc.)
        """
        self.maintenance_timer = QTimer(self)
        self.maintenance_timer.timeout.connect(self.perform_maintenance)
        # Run maintenance every 25 seconds (equivalent to C# dkk >= 25)
        maintenance_interval = int(SETTINGS.get('maintenance_interval', 25)) * 1000  # Convert to milliseconds
        self.maintenance_timer.start(maintenance_interval)
        logging.info(f"Maintenance timer started with {maintenance_interval/1000} second interval")

    def init_time_timer(self):
        """Initialize timer for updating time display"""
        self.time_timer = QTimer(self)
        self.time_timer.timeout.connect(self.update_time_display)
        self.time_timer.start(1000)  # Update every second
        self.update_time_display()  # Initial update

    def init_schedule_timer(self):
        """Initialize timer for checking the schedule every minute."""
        self.schedule_timer = QTimer(self)
        self.schedule_timer.timeout.connect(self.check_schedule)
        self.schedule_timer.start(60000)  # Check every 60 seconds
        logging.info("Schedule check timer started with 1 minute interval")

    def perform_maintenance(self):
        """
        Perform periodic maintenance tasks, including fetching the schedule.
        """
        try:
            logging.info("Performing periodic maintenance tasks")
            
            # Get board values/schedule
            all_boards_data = self.network_client.get_values()
            if all_boards_data:
                logging.info(f"Retrieved {len(all_boards_data)} board configurations")
                # Find this board's schedule
                my_board_id_str = SETTINGS.get('board_id', '0')
                for board_data in all_boards_data:
                    if str(board_data.get('id')) == my_board_id_str:
                        self.schedule = board_data
                        logging.info(f"Successfully loaded schedule for board {my_board_id_str}")
                        break
                else:
                    logging.warning(f"Could not find schedule for board ID {my_board_id_str} in server response.")

            # Check for version updates
            new_version = self.network_client.check_version()
            if new_version and new_version != SETTINGS.get('version'):
                logging.info(f"Version update available: {SETTINGS.get('version')} -> {new_version}")
                # TODO: Add UI notification or auto-update trigger
                
        except Exception as e:
            logging.error(f"Error in maintenance tasks: {e}")

    def _format_time(self, time_str):
        """Saat formatını HH:MM formatına çevir (C# Tools.ClockFrmt karşılığı)"""
        if not time_str or time_str == "0":
            return ""
        time_str = time_str.strip()
        parts = time_str.split(':')
        if len(parts) == 2:
            try:
                h = int(parts[0])
                m = int(parts[1])
                return f"{h:02d}:{m:02d}"
            except ValueError:
                return ""
        return time_str if len(time_str) == 5 else ""

    def check_schedule(self):
        """Check the current time against the schedule and lock/unlock accordingly.
        
        İki aşamalı kontrol:
        1. Ders saati içindeyse aç (mevcut mantık)
        2. Çıkış saati geldiğinde kilitle (C# timer1Thread mantığı)
        """
        if not self.schedule or 'hours' not in self.schedule:
            logging.debug("Schedule not available, skipping check.")
            return

        now = datetime.now()
        # isoweekday(): Monday is 1 and Sunday is 7. This matches the C# loop (s=1 to 7)
        day_of_week = now.isoweekday()
        current_time_str = now.strftime("%H:%M")

        # Gün değiştiğinde exit_time_locked dizisini sıfırla (C# kSaat[] gibi)
        if day_of_week != self.last_schedule_day:
            self.exit_time_locked = [0] * 20
            self.last_schedule_day = day_of_week
            logging.info(f"New day detected ({day_of_week}), reset exit_time_locked counters")

        is_in_unlocked_period = False
        exit_time_triggered = False
        exit_time_log = ""
        try:
            hours_data = self.schedule['hours']

            # Handle both list and dict structures
            if isinstance(hours_data, list):
                # Server returns hours as a 3D list: [day][period][property]
                # day: 0-7 (we use day_of_week which is 1-7 for Mon-Sun)
                # period: 0-18 (we check 1-18)
                # property: 0-2 where 1=start_time, 2=end_time

                if day_of_week < len(hours_data):
                    day_schedule = hours_data[day_of_week]

                    # Check each period (1-18)
                    for period_idx in range(1, min(19, len(day_schedule))):
                        period_data = day_schedule[period_idx]

                        if isinstance(period_data, list) and len(period_data) >= 3:
                            start_time = period_data[1] if len(period_data) > 1 else ""
                            end_time = period_data[2] if len(period_data) > 2 else ""

                            if start_time and end_time and start_time != "0" and end_time != "0" and start_time != "" and end_time != "":
                                # Ders saati içinde mi? (mevcut mantık)
                                if start_time <= current_time_str < end_time:
                                    is_in_unlocked_period = True
                                    logging.debug(f"Current time {current_time_str} is in unlocked period: {start_time}-{end_time}")

                                # --- C# timer1Thread mantığı: Çıkış saati kontrolü ---
                                # Çıkış saati geldiğinde kilitle (tenefüs/ders bitimi)
                                formatted_exit = self._format_time(end_time)
                                if formatted_exit and len(formatted_exit) == 5 and not self.is_locked:
                                    if self.exit_time_locked[period_idx] == 0:
                                        if current_time_str == formatted_exit:
                                            # Tam çıkış saatinde kilitle
                                            self.exit_time_locked[period_idx] = 1
                                            exit_time_triggered = True
                                            exit_time_log = f"Tenefüs olduğu için kilitlendi (Ders {period_idx}, çıkış: {formatted_exit})"
                                            logging.info(exit_time_log)
                                        else:
                                            # 2-5 dakika tolerans (C# kodundaki gibi)
                                            try:
                                                from datetime import timedelta
                                                current_dt = datetime.strptime(current_time_str, "%H:%M")
                                                exit_dt = datetime.strptime(formatted_exit, "%H:%M")
                                                diff_minutes = (current_dt - exit_dt).total_seconds() / 60
                                                if 2 < diff_minutes < 5:
                                                    self.exit_time_locked[period_idx] = 1
                                                    exit_time_triggered = True
                                                    exit_time_log = f"Tenefüs olduğu için kilitlendi (Ders {period_idx}, çıkış: {formatted_exit}, +{diff_minutes:.0f}dk)"
                                                    logging.info(exit_time_log)
                                            except Exception as te:
                                                logging.debug(f"Time comparison error: {te}")

            elif isinstance(hours_data, dict):
                # Handle dictionary format (if server changes to this format)
                day_schedule = hours_data.get(str(day_of_week), {})

                # The hour slots are also 1-indexed strings "1" through "18"
                for k in range(1, 19):
                    slot = day_schedule.get(str(k))
                    # Slot is expected to be a dict like {'1': '08:30', '2': '09:10'}
                    if slot and isinstance(slot, dict):
                        start_time = slot.get('1')
                        end_time = slot.get('2')

                        if start_time and end_time and start_time != "0" and end_time != "0":
                            if start_time <= current_time_str < end_time:
                                is_in_unlocked_period = True

                            # Çıkış saati kontrolü (dict format)
                            formatted_exit = self._format_time(end_time)
                            if formatted_exit and len(formatted_exit) == 5 and not self.is_locked:
                                if self.exit_time_locked[k] == 0:
                                    if current_time_str == formatted_exit:
                                        self.exit_time_locked[k] = 1
                                        exit_time_triggered = True
                                        exit_time_log = f"Tenefüs olduğu için kilitlendi (Ders {k}, çıkış: {formatted_exit})"
                                        logging.info(exit_time_log)
                                    else:
                                        try:
                                            from datetime import timedelta
                                            current_dt = datetime.strptime(current_time_str, "%H:%M")
                                            exit_dt = datetime.strptime(formatted_exit, "%H:%M")
                                            diff_minutes = (current_dt - exit_dt).total_seconds() / 60
                                            if 2 < diff_minutes < 5:
                                                self.exit_time_locked[k] = 1
                                                exit_time_triggered = True
                                                exit_time_log = f"Tenefüs olduğu için kilitlendi (Ders {k}, çıkış: {formatted_exit}, +{diff_minutes:.0f}dk)"
                                                logging.info(exit_time_log)
                                        except Exception as te:
                                            logging.debug(f"Time comparison error: {te}")
            else:
                logging.warning(f"Unexpected hours data type: {type(hours_data)}")

        except (IndexError, KeyError, TypeError) as e:
            logging.warning(f"Could not parse schedule for today (day {day_of_week}): {e}")
            # Schedule parse hatası olduğunda kilitleme YAPMA
            # (internetsiz durumda schedule yoksa açık kalmalı)
            return

        # --- Çıkış saati bazlı kilitleme (öncelikli) ---
        # C# timer1Thread: çıkış saati geldiğinde USB yoksa kilitle
        if exit_time_triggered and not self.is_locked:
            if check_usb_password():
                logging.info("Exit time says lock, but USB is present. Skipping lock.")
            else:
                self.manual_override = False
                self.lock_system(exit_time_log)
                self.save_log(exit_time_log, "schedule")
                return  # Çıkış saati kilitledi, aşağıdaki mantığa geçme

        # --- Apply Locking/Unlocking Logic (mevcut mantık) ---
        if is_in_unlocked_period:
            # It's time to be unlocked.
            if self.is_locked:
                self.manual_override = False # Reset override on any schedule action
                self.unlock_system("Zamanlanmış kilit açma")
        else:
            # It's time to be locked.
            if not self.is_locked:
                # Check if USB with password is present - if so, don't lock
                if check_usb_password():
                    logging.info("Schedule says lock, but USB is present. Skipping lock.")
                elif self.manual_override:
                    logging.info("Schedule says lock, but manual override is active. Skipping lock.")
                    # Keep manual_override active until the next scheduled unlock period
                else:
                    self.lock_system("Zamanlanmış kilitleme")
        
    def check_usb_status(self):
        """
        NEW: Periodic USB status check (equivalent to C# CheckInternetWork function)
        Only locks system if it was originally unlocked by USB
        """
        try:
            # Check if USB with password is present
            usb_present = check_usb_password()
            
            if usb_present:
                # USB is present - unlock if locked, but only call unlock ONCE
                if self.is_locked:
                    logging.info("USB password detected - unlocking system")
                    self.unlock_system("USB ile açıldı")
                # Keep manual_override active while USB is present to prevent schedule from re-locking
                elif self.usb_monitor.unlocked_by_usb:
                    # USB still present, make sure manual_override stays active
                    self.manual_override = True
            else:
                # USB with password not present
                if not self.is_locked and self.usb_monitor.unlocked_by_usb:
                    # Only lock if system was unlocked by USB
                    logging.info("USB password not found and system was unlocked by USB - locking system")
                    self.lock_system("USB çıkarıldığı için kilitlendi")
                    # Reset the USB unlock flag since we're locking
                    self.usb_monitor.unlocked_by_usb = False
                    
            # Check for remove command
            if check_usb_remove():
                self.remove_system()
                
        except Exception as e:
            logging.error(f"Error in USB status check: {e}")
        
    def _get_headers(self, core_code: str) -> dict:
        def cFnc_original(code_str: str) -> str:
            """
            A direct Python port of the original C# cFnc function.
            It includes the problematic '?' and a timestamp.
            """
            timestamp = str(time.time())
            s = f"{code_str}?{timestamp}"
            
            # the original replacement map.
            replacements = {
                "0":"!g", "1":"gt", "2":"_a", "3":"me", "4":"?b", 
                "5":"_z", "6":"fi", "7":"+d", "8":"da", "9":"|k",
                " ":"kz", ".":"?u", ":":"wa"
            }
            for old, new in replacements.items(): 
                s = s.replace(old, new)
            return s
            
        headers = {
            "User-Agent": SETTINGS.get('user_agent', 'agent_SmartBoart'), 
            "User-Key": generate_user_key(), 
            "UserCore": cFnc_original(core_code)
        }
        logging.debug(f"Sending request with ORIGINAL headers: {headers}")
        return headers

    def poll_server(self):
        response_text = self.network_client.ctrl_post()
        if response_text:
            logging.info("Successfully polled server.")
            commands = response_text.split(',')
            self.process_commands(commands)
        else:
            self.message_label.setText("Sunucuya Bağlanılamıyor...")
            logging.error("Failed to poll server.")

    def process_commands(self, commands):
        if len(commands) < 5: return
        try:
            self.tahta_lock = int(commands[0])
            message = commands[1] if commands[1] != '0' else "Sistem Kilitli"
            self.shutDown = int(commands[2])
            self.system_remove = int(commands[3])
            self.log_send = int(commands[4])
            
            self.message_label.setText(message)
            
            if self.tahta_lock == 1 and not self.is_locked:
                # Don't lock if USB with password is present (regardless of how it was unlocked)
                if check_usb_password():
                    logging.info("Server says lock, but USB is present. Skipping lock.")
                elif self.manual_override:
                    logging.info("Server says lock, but manual override is active (password/USB unlock). Skipping lock.")
                else:
                    self.lock_system("Sunucudan gelen komut ile kilitlendi")
            elif self.tahta_lock == 0 and self.is_locked:
                self.unlock_system("Sunucudan gelen komut ile açıldı")
            
            if self.shutDown == 1:
                logging.info("Shutdown command received from server (mobile app)")
                self.acknowledge_command("shutdown", "0")
                self.save_log("Sunucudan kapatma komutu alındı", "system")
                # Birden fazla kapatma yöntemi dene
                import subprocess
                shutdown_commands = [
                    ['sudo', 'poweroff'],
                    ['sudo', 'systemctl', 'poweroff'],
                    ['sudo', '/sbin/poweroff'],
                    ['sudo', 'shutdown', '-h', 'now'],
                    ['poweroff'],
                ]
                for cmd in shutdown_commands:
                    try:
                        logging.info(f"Trying server shutdown command: {' '.join(cmd)}")
                        result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                        if result.returncode == 0:
                            logging.info(f"Shutdown initiated with: {' '.join(cmd)}")
                            QApplication.quit()
                            return
                    except subprocess.TimeoutExpired:
                        # Sistem kapanıyor olabilir
                        QApplication.quit()
                        return
                    except Exception as e:
                        logging.warning(f"Server shutdown command {cmd} failed: {e}")
                        continue
                # Son çare
                os.system("sudo poweroff || poweroff")
                QApplication.quit()
            
            if self.system_remove == 1:
                self.remove_system()
        except (ValueError, IndexError) as e:
            logging.error(f"Error processing server commands '{commands}': {e}")

    def lock_system(self, reason=""):
        if not self.is_locked: # Prevent redundant locks
            logging.info(f"Locking system: {reason}")
            self.is_locked = True
            
            # NEW: Log the lock event and notify the server
            self.save_log(reason, "lock")
            self.acknowledge_command("tahtaLock", "1")

            # Ensure UI elements are visible
            self.login_button.setVisible(True)
            self.message_label.setVisible(True)

            # Show, raise, and activate the window.
            self.showFullScreen()
            self.raise_()
            self.activateWindow()
            self.login_button.setFocus()
            
            QApplication.processEvents()

            if not self.keyboard_locker or not self.keyboard_locker.is_alive():
                self.keyboard_locker = KeyboardLocker()
                self.keyboard_locker.start()

    def unlock_system(self, reason=""):
        logging.info(f"Unlocking system: {reason}")

        # Set manual override if this is not a scheduled or server-commanded unlock
        if "Zamanlanmış" not in reason and "Sunucudan" not in reason:
            self.manual_override = True
            logging.info("Manual override activated.")

        self.is_locked = False
        self.hide()
        if self.keyboard_locker:
            self.keyboard_locker.stop()
            self.keyboard_locker = None
            
        # NEW: Reset USB unlock flag if unlocked by other means (not USB)
        if not reason.startswith("USB ile"):
            self.usb_monitor.reset_usb_unlock_flag()
            
        self.acknowledge_command("tahtaLock", "0")
        
        # Fatih kilidi açıldıktan sonra Pardus/GNOME ekran kilidini aktif et
        # Böylece kullanıcı Pardus şifresiyle giriş yapabilir
        self.activate_system_lock_screen()

    def activate_system_lock_screen(self):
        """
        Fatih kilit ekranı açıldıktan sonra Pardus/GNOME sistem kilidini aktif eder.
        Kullanıcı kendi şifresiyle giriş yaparak sisteme erişir.
        """
        import subprocess
        
        logging.info("Activating Pardus/GNOME lock screen...")
        
        # Birkaç farklı yöntem deneyeceğiz (Pardus/Debian için)
        lock_commands = [
            # GNOME Screensaver (en yaygın)
            ['gnome-screensaver-command', '--lock'],
            # loginctl (systemd-based)
            ['loginctl', 'lock-session'],
            # xdg-screensaver (generic)
            ['xdg-screensaver', 'lock'],
            # dbus-send (GNOME Shell)
            ['dbus-send', '--type=method_call', '--dest=org.gnome.ScreenSaver',
             '/org/gnome/ScreenSaver', 'org.gnome.ScreenSaver.Lock'],
        ]
        
        for cmd in lock_commands:
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    logging.info(f"System lock screen activated using: {cmd[0]}")
                    return True
                else:
                    logging.debug(f"Command {cmd[0]} failed: {result.stderr}")
            except FileNotFoundError:
                logging.debug(f"Command not found: {cmd[0]}")
            except subprocess.TimeoutExpired:
                logging.warning(f"Command timed out: {cmd[0]}")
            except Exception as e:
                logging.debug(f"Error running {cmd[0]}: {e}")
        
        logging.warning("Could not activate system lock screen - no supported method found")
        return False

    def acknowledge_command(self, column, value):
        self.network_client.set_value(column, value)

    def remove_system(self):
        logging.info("SYSTEM REMOVE command received. Uninstalling...")
        self.acknowledge_command("system_Remove", "0")
        os.system("rm -f /etc/xdg/autostart/fatih-client-autostart.desktop")
        os.system("rm -rf /opt/fatih-client")
        os.system("rm -f /etc/fatih-client/config.ini")
        logging.info("Uninstallation complete. Exiting.")
        QApplication.quit()

    # --- NEW: Log saving method that uses the network client ---
    def save_log(self, log_name, vog_name):
        # Run in a separate thread to avoid blocking the UI
        threading.Thread(
            target=self.network_client.save_log,
            args=(log_name, vog_name),
            daemon=True
        ).start()

    def update_time_display(self):
        """Update the time display in bottom-right corner"""
        current_time = datetime.now()
        time_str = current_time.strftime("%d/%m/%Y %H:%M:%S")
        self.time_label.setText(time_str)

    def update_board_id_display(self):
        """Update the board name display in top-center - Sadece TAHTA ADI görünür"""
        board_name = SETTINGS.get('board_name', 'Akıllı Tahta')
        self.board_id_label.setText(board_name)

    def show_login_dialog(self):
        """Show the login dialog"""
        logging.info("Login button clicked!")
        print("Login button clicked!")

        if not self.is_locked:
            logging.info("System is not locked, not showing login dialog")
            return

        try:
            logging.info("Creating login dialog...")
            login_dialog = LoginDialog(self)
            logging.info("Executing login dialog...")
            result = login_dialog.exec()
            logging.info(f"Login dialog result: {result}")

            if result == QDialog.DialogCode.Accepted:
                logging.info("Login successful, hiding login button")
                self.login_button.hide()
        except Exception as e:
            logging.error(f"Error in login dialog: {e}")
            print(f"Error in login dialog: {e}")

    def validate_admin_password(self, password):
        """
        Şifre doğrulama - Önce config'deki admin şifresi, sonra Mebrecep dinamik şifre
        
        1. Config'deki admin_password ile kontrol
        2. Dinamik şifre (Mebrecep) ile kontrol
        """
        # Önce config'deki admin şifresi ile kontrol et
        config_password = SETTINGS.get('admin_password', 'mebre')
        if password == config_password:
            logging.info("Password validated via config admin_password")
            return True

        # Dinamik şifre kontrolü (sunucu ve Mebrecep aynı algoritmayı kullanıyor)
        if validate_dynamic_password(password):
            logging.info("Password validated via dynamic algorithm (Mebrecep)")
            return True
        
        logging.warning("Invalid password - does not match config or dynamic algorithm")
        return False

    def show_context_menu(self, position):
        """Show right-click context menu"""
        context_menu = QMenu(self)

        # NEW: Manual Lock Action
        if not self.is_locked:
            lock_action = QAction("Tahtayı Kilitle", self)
            lock_action.triggered.connect(lambda: self.lock_system("Kullanıcı tarafından manuel kilitlendi"))
            context_menu.addAction(lock_action)
            context_menu.addSeparator()

        # System status
        status_action = QAction("Sistem Durumu", self)
        status_action.triggered.connect(self.show_system_status)
        context_menu.addAction(status_action)

        # Ayarlar kaldırıldı - müşteri isteği
        # settings_action = QAction("Ayarlar", self)
        # settings_action.triggered.connect(self.show_settings)
        # context_menu.addAction(settings_action)

        context_menu.addSeparator()

        # Board configuration
        board_config_action = QAction("Tahta Yapılandırması", self)
        board_config_action.triggered.connect(self.show_board_config)
        context_menu.addAction(board_config_action)

        # Change password
        change_pass_action = QAction("Şifre Değiştir", self)
        change_pass_action.triggered.connect(self.show_change_password)
        context_menu.addAction(change_pass_action)

        context_menu.addSeparator()

        # On-screen keyboard
        keyboard_action = QAction("Ekran Klavyesi", self)
        keyboard_action.triggered.connect(self.show_on_screen_keyboard)
        context_menu.addAction(keyboard_action)

        # Kayıtları Görüntüle kaldırıldı - müşteri isteği
        # logs_action = QAction("Kayıtları Görüntüle", self)
        # logs_action.triggered.connect(self.show_logs)
        # context_menu.addAction(logs_action)

        context_menu.addSeparator()

        # System control
        restart_action = QAction("Yeniden Başlat", self)
        restart_action.triggered.connect(self.restart_system)
        context_menu.addAction(restart_action)

        shutdown_action = QAction("Kapat", self)
        shutdown_action.triggered.connect(self.shutdown_system)
        context_menu.addAction(shutdown_action)

        context_menu.addSeparator()

        # About
        about_action = QAction("Hakkında", self)
        about_action.triggered.connect(self.show_about)
        context_menu.addAction(about_action)

        context_menu.exec(QCursor.pos())

    def show_system_status(self):
        """Show system status dialog - Kurum kodu kaldırıldı"""
        board_name = SETTINGS.get('board_name', 'Akıllı Tahta')
        status_text = f"""
Sistem Durumu:

Tahta Adı: {board_name}
Versiyon: {SETTINGS.get('version')}.{SETTINGS.get('sub_version')}
Sistem Kilidi: {'Aktif' if self.is_locked else 'Pasif'}
USB Bağlı: {'Evet' if check_usb_password() else 'Hayır'}
Ağ Bağlantısı: {'Var' if self.network_client.check_network() else 'Yok'}
_________________________________________________________________________________________
"""
        QMessageBox.information(self, "Sistem Durumu", status_text.strip())

    def show_settings(self):
        """Show settings dialog"""
        settings_text = f"""
Mevcut Ayarlar:

API URL: {SETTINGS.get('api_url')}
Polling Aralığı: {SETTINGS.get('polling_interval', 5)} saniye
USB Kontrol Aralığı: {SETTINGS.get('usb_check_interval', 3)} saniye
Bakım Aralığı: {SETTINGS.get('maintenance_interval', 25)} saniye

Bu ayarlar config.ini dosyasından değiştirilebilir.
_________________________________________________________________________________________
"""
        QMessageBox.information(self, "Ayarlar", settings_text.strip())

    def show_on_screen_keyboard(self):
        """Show on-screen keyboard"""
        keyboard = OnScreenKeyboard()
        keyboard.exec()

    def show_logs(self):
        """Show recent logs"""
        log_file = os.path.expanduser("~/fatih_client.log")
        if os.path.exists(log_file):
            try:
                with open(log_file, 'r') as f:
                    logs = f.read()
                log_dialog = QDialog(self)
                log_dialog.setWindowTitle("Sistem Kayıtları")
                log_dialog.setModal(True)
                layout = QVBoxLayout()
                log_text = QTextEdit()
                log_text.setPlainText(logs)
                log_text.setReadOnly(True)
                layout.addWidget(log_text)
                close_btn = QPushButton("Kapat")
                close_btn.clicked.connect(log_dialog.accept)
                layout.addWidget(close_btn)
                log_dialog.setLayout(layout)
                log_dialog.resize(600, 400)
                log_dialog.exec()
            except Exception as e:
                QMessageBox.warning(self, "Hata", f"Kayıtlar okunamadı: {e}")
        else:
            QMessageBox.information(self, "Bilgi", "Henüz kayıt dosyası oluşturulmamış.")

    def restart_system(self):
        """Restart the system"""
        reply = QMessageBox.question(
            self, "Yeniden Başlat",
            "Sistemi yeniden başlatmak istediğinizden emin misiniz?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if reply == QMessageBox.StandardButton.Yes:
            self.save_log("Sistem yeniden başlatıldı", "system")
            import subprocess
            # Birden fazla yöntem dene (hangisi sistemde mevcutsa)
            reboot_commands = [
                ['sudo', 'reboot'],
                ['sudo', 'systemctl', 'reboot'],
                ['sudo', '/sbin/reboot'],
                ['systemctl', 'reboot'],
                ['reboot'],
            ]
            for cmd in reboot_commands:
                try:
                    logging.info(f"Trying reboot command: {' '.join(cmd)}")
                    result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                    if result.returncode == 0:
                        logging.info(f"Reboot initiated with: {' '.join(cmd)}")
                        return
                except FileNotFoundError:
                    continue
                except subprocess.TimeoutExpired:
                    # Komut çalıştı, sistem kapanıyor olabilir
                    return
                except Exception as e:
                    logging.warning(f"Reboot command {cmd} failed: {e}")
                    continue
            # Son çare: os.system ile dene
            logging.warning("All reboot methods failed, trying os.system")
            os.system("sudo reboot || reboot")

    def shutdown_system(self):
        """Shutdown the system"""
        reply = QMessageBox.question(
            self, "Kapat",
            "Sistemi kapatmak istediğinizden emin misiniz?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if reply == QMessageBox.StandardButton.Yes:
            self.save_log("Sistem kapatıldı", "system")
            import subprocess
            # Birden fazla yöntem dene (hangisi sistemde mevcutsa)
            shutdown_commands = [
                ['sudo', 'poweroff'],
                ['sudo', 'systemctl', 'poweroff'],
                ['sudo', '/sbin/poweroff'],
                ['sudo', 'shutdown', '-h', 'now'],
                ['systemctl', 'poweroff'],
                ['poweroff'],
            ]
            for cmd in shutdown_commands:
                try:
                    logging.info(f"Trying shutdown command: {' '.join(cmd)}")
                    result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                    if result.returncode == 0:
                        logging.info(f"Shutdown initiated with: {' '.join(cmd)}")
                        return
                except FileNotFoundError:
                    continue
                except subprocess.TimeoutExpired:
                    # Komut çalıştı, sistem kapanıyor olabilir
                    return
                except Exception as e:
                    logging.warning(f"Shutdown command {cmd} failed: {e}")
                    continue
            # Son çare: os.system ile dene
            logging.warning("All shutdown methods failed, trying os.system")
            os.system("sudo poweroff || poweroff")

    def show_about(self):
        """Show about dialog"""
        about_text = f"""
Fatih Akıllı Tahta İstemcisi

Versiyon: {SETTINGS.get('version')}.{SETTINGS.get('sub_version')}

Bu yazılım Fatih Projesi kapsamında geliştirilmiştir.
Akıllı tahta güvenliği ve yönetimi için tasarlanmıştır.
"""
        QMessageBox.about(self, "Hakkında", about_text.strip())

    def show_board_config(self):
        """Show board configuration dialog"""
        config_dialog = BoardConfigDialog(self, network_client=self.network_client)
        config_dialog.exec()

    def show_change_password(self):
        """Show change password dialog"""
        change_dialog = ChangePasswordDialog(self)
        change_dialog.exec()

    def process_admin_command(self):
        """Process admin commands (equivalent to C#textBox1_KeyDown)"""
        command = self.admin_input.text().strip()
        logging.info(f"Admin command received: {command}")

        if command == "_*:swf":
            self.unlock_system("Admin komutu ile açıldı")
            self.save_log("Admin komutu ile sistem açıldı", "admin")
        elif command == "_*:sl":
            self.lock_system("Admin komutu ile kilitlendi")
            self.save_log("Admin komutu ile sistem kilitlendi", "admin")
        elif command == "_*:cs":
            status = f"Sdwn:{self.shutDown} Tlck:{self.tahta_lock} Rmv:{self.system_remove} logS:{self.log_send}"
            self.message_label.setText(status)
        elif command == "_*:is":
            info = f"{SETTINGS.get('board_name', 'Board')},{SETTINGS.get('corporate_code')},{SETTINGS.get('board_id')}"
            self.message_label.setText(info)
        elif command == "_*:cls":
            self.admin_input.hide()
            self.message_label.setText(f"[{SETTINGS.get('version')}] {SETTINGS.get('board_name', 'Board')}")
        elif command.startswith("_*:pass"):
            # Password change command
            parts = command.split()
            if len(parts) == 2:
                new_password = parts[1]
                # In a real implementation, you'd save this to config
                logging.info(f"Admin password changed to: {new_password}")
                self.message_label.setText("Şifre değiştirildi")
        elif command == "_*:save":
            # Save configuration
            logging.info("Configuration saved by admin command")
            self.message_label.setText("Ayarlar kaydedildi")
        elif command == "_*:aop":
            self.show_settings()
        elif command == "_*:opgy":
            # Disable task manager equivalent
            logging.info("Task manager disabled by admin command")
            self.message_label.setText("Görev yöneticisi devre dışı")
        elif command == "_*:srmv":
            self.remove_system()

        # Clear the input after processing
        self.admin_input.clear()
        self.admin_input.hide()

    def keyPressEvent(self, event):
        """Handle key press events for admin interface"""
        if event.key() == Qt.Key.Key_K and event.modifiers() == Qt.KeyboardModifier.ControlModifier:
            # Toggle admin input visibility
            if self.admin_input.isVisible():
                self.admin_input.hide()
            else:
                self.admin_input.show()
                self.admin_input.setFocus()
        else:
            super().keyPressEvent(event)

    def resizeEvent(self, event):
        """Handle window resize to reposition UI elements"""
        super().resizeEvent(event)

        # Update background to fill window
        if hasattr(self, 'background'):
            self.background.setGeometry(self.rect())

        # Reposition login button
        if hasattr(self, 'login_button'):
            screen_center_x = self.width() // 2
            screen_center_y = self.height() // 2
            button_width = 280
            button_height = 60
            self.login_button.move(screen_center_x - button_width // 2, screen_center_y + 80)

        # Reposition other UI elements
        if hasattr(self, 'message_label'):
            self.message_label.setGeometry(50, self.height() // 2 - 100, self.width() - 100, 200)

        if hasattr(self, 'time_label'):
            self.time_label.setGeometry(self.width() - 250, self.height() - 50, 240, 40)

        if hasattr(self, 'board_id_label'):
            label_width = 450
            label_height = 100
            label_x = (self.width() - label_width) // 2
            self.board_id_label.setGeometry(label_x, 20, label_width, label_height)

def main():
    try:
        logging.info("Starting Fatih Client application...")
        print("Starting Fatih Client application...")

        app = QApplication(sys.argv)
        # Note: High DPI scaling attributes not available in this PyQt6 version

        window = FatihClientApp()
        logging.info("FatihClientApp created successfully")

        window.lock_system("Sistem başlatıldı")
        logging.info("System locked on startup")

        print("Application started successfully - login button should be visible")
        sys.exit(app.exec())
    except Exception as e:
        logging.critical(f"Unhandled exception in main: {e}", exc_info=True)
        print(f"Critical error: {e}")

def main_kiosk():
    """
    Kiosk mode for pre-login lock screen.
    Shows only the lock screen, exits after unlock to allow real user login.
    """
    try:
        logging.info("=== Starting Fatih Client in KIOSK MODE ===")
        app = QApplication(sys.argv)

        # Create a simplified kiosk window
        kiosk = FatihKioskMode()
        kiosk.showFullScreen()

        logging.info("Kiosk mode started - waiting for unlock")
        sys.exit(app.exec())
    except Exception as e:
        logging.critical(f"Unhandled exception in kiosk mode: {e}", exc_info=True)
        print(f"Critical error in kiosk mode: {e}")
        sys.exit(1)

class FatihKioskMode(QMainWindow):
    """
    Kiosk mode that shows lock screen before user login.
    Supports: USB unlock, password unlock, mobile app unlock (server polling),
    and remote shutdown command.
    Normal modla aynı görünümde çalışır (duvar kağıdı, saat, tahta adı).
    """
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Fatih Sistem Kilidi")
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint)
        self.setGeometry(QApplication.primaryScreen().geometry())

        # Mouse tracking ve right-click desteği
        self.setMouseTracking(True)
        self.setContextMenuPolicy(Qt.CustomContextMenu)
        self.customContextMenuRequested.connect(self.show_kiosk_context_menu)

        # Network client for server polling (mobile app unlock + shutdown)
        self.network_client = NetworkClient(SETTINGS)

        # Background image (normal modla aynı)
        self.background = QLabel(self)
        bg_image_path = os.path.join(RESOURCES_DIR, "Artboard 3.png")
        if os.path.exists(bg_image_path):
            self.background.setPixmap(QPixmap(bg_image_path))
        else:
            logging.warning(f"Kiosk: Background image not found: {bg_image_path}")
            self.background.setStyleSheet("background-color: #1a1a2e;")
        self.background.setScaledContents(True)
        self.background.setGeometry(self.rect())

        # Time display (bottom-right corner - normal modla aynı)
        self.time_label = QLabel("", self)
        self.time_label.setStyleSheet("color: white; font-size: 18px; background-color: rgba(0,0,0,0.7); padding: 5px;")
        self.time_label.setAlignment(Qt.AlignRight)
        self.time_label.setGeometry(self.width() - 250, self.height() - 50, 240, 40)

        # Board Name display (top-center - normal modla aynı)
        self.board_id_label = QLabel("", self)
        self.board_id_label.setStyleSheet("""
            QLabel {
                color: white; 
                background-color: rgba(0, 0, 0, 220); 
                padding: 25px 40px;
                border-radius: 10px;
            }
        """)
        self.board_id_label.setFont(QFont('Sans', 20, QFont.Bold))
        self.board_id_label.setAlignment(Qt.AlignCenter)
        label_width = 450
        label_height = 100
        label_x = (self.width() - label_width) // 2
        self.board_id_label.setGeometry(label_x, 20, label_width, label_height)
        self.board_id_label.setMinimumHeight(label_height)
        board_name = SETTINGS.get('board_name', 'Akıllı Tahta')
        self.board_id_label.setText(board_name)

        # Status message label
        self.message_label = QLabel("Sistem Kilitli - Devam etmek için giriş yapın", self)
        self.message_label.setStyleSheet("color: white; font-size: 32px; background-color: rgba(0,0,0,0.5);")
        self.message_label.setAlignment(Qt.AlignCenter)
        self.message_label.setWordWrap(True)
        self.message_label.setGeometry(50, self.height() // 2 - 100, self.width() - 100, 200)

        # Login button - normal modla aynı stil
        self.login_button = QPushButton("TAHTAYI AÇ", self)
        self.login_button.setStyleSheet("background-color: #0066cc; color: white; border: 3px solid white; border-radius: 10px;")
        self.login_button.setFont(QFont('DejaVu Sans', 18))
        self.login_button.clicked.connect(self.show_login)
        button_width = 280
        button_height = 60
        self.login_button.setFixedSize(button_width, button_height)
        screen_center_x = self.width() // 2
        screen_center_y = self.height() // 2
        self.login_button.move(screen_center_x - button_width // 2, screen_center_y + 80)
        self.login_button.raise_()
        self.login_button.setVisible(True)
        self.login_button.show()

        # Keyboard locker
        self.keyboard_locker = KeyboardLocker()
        self.keyboard_locker.start()

        # USB check timer (3 seconds)
        self.usb_timer = QTimer(self)
        self.usb_timer.timeout.connect(self.check_usb_for_unlock)
        self.usb_timer.start(3000)

        # Server polling timer (5 seconds) - mobil uygulama ile kilit açma/kapatma
        self.server_timer = QTimer(self)
        self.server_timer.timeout.connect(self.poll_server)
        self.server_timer.start(5000)

        # Time update timer (1 second)
        self.time_timer = QTimer(self)
        self.time_timer.timeout.connect(self.update_time_display)
        self.time_timer.start(1000)
        self.update_time_display()

        logging.info("Kiosk mode UI initialized with background, clock, USB monitoring, and server polling")

    def update_time_display(self):
        """Update the time display in bottom-right corner"""
        current_time = datetime.now()
        time_str = current_time.strftime("%d/%m/%Y %H:%M:%S")
        self.time_label.setText(time_str)

    def check_usb_for_unlock(self):
        """Check USB for unlock password"""
        usb_password = check_usb_password()
        if usb_password:
            logging.info(f"Kiosk mode unlocked by USB: {usb_password}")
            self.unlock_and_exit()

    def poll_server(self):
        """
        Poll server for commands (mobile app unlock + shutdown).
        tahta_lock=0 → unlock, shutDown=1 → shutdown
        """
        try:
            response_text = self.network_client.ctrl_post()
            if response_text:
                commands = response_text.split(',')
                if len(commands) >= 5:
                    tahta_lock = int(commands[0])
                    shut_down = int(commands[2])
                    system_remove = int(commands[3])
                    
                    # Update message from server
                    message = commands[1] if commands[1] != '0' else "Sistem Kilitli"
                    self.message_label.setText(message)
                    
                    # Mobile app unlock: tahta_lock=0 means unlock
                    if tahta_lock == 0:
                        logging.info("Kiosk: Server says unlock (mobile app)")
                        self.unlock_and_exit()
                        return
                    
                    # Shutdown command from mobile app
                    if shut_down == 1:
                        logging.info("Kiosk: Shutdown command from server (mobile app)")
                        # Acknowledge the command
                        self.network_client.set_value("shutdown", "0")
                        import subprocess
                        shutdown_commands = [
                            ['sudo', 'poweroff'],
                            ['sudo', 'systemctl', 'poweroff'],
                            ['sudo', '/sbin/poweroff'],
                            ['sudo', 'shutdown', '-h', 'now'],
                            ['poweroff'],
                        ]
                        for cmd in shutdown_commands:
                            try:
                                logging.info(f"Kiosk: Trying shutdown command: {' '.join(cmd)}")
                                result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                                if result.returncode == 0:
                                    logging.info(f"Kiosk: Shutdown initiated with: {' '.join(cmd)}")
                                    QApplication.quit()
                                    return
                            except subprocess.TimeoutExpired:
                                QApplication.quit()
                                return
                            except Exception as e:
                                logging.warning(f"Kiosk: Shutdown command {cmd} failed: {e}")
                                continue
                        os.system("sudo poweroff || poweroff")
                        QApplication.quit()
                        return
                    
                    # System remove command
                    if system_remove == 1:
                        logging.info("Kiosk: System remove command from server")
                        self.unlock_and_exit()
                        return
            else:
                logging.debug("Kiosk: Server unreachable or no response")
        except Exception as e:
            logging.debug(f"Kiosk: Server poll error: {e}")

    def show_kiosk_context_menu(self, position):
        """Kiosk modunda sağ tık menüsü - Normal moddaki tüm seçenekler"""
        context_menu = QMenu(self)
        context_menu.setStyleSheet("""
            QMenu {
                background-color: #2b2b2b;
                color: white;
                border: 1px solid #555;
                padding: 5px;
                font-size: 14px;
            }
            QMenu::item {
                padding: 8px 25px;
                min-width: 200px;
            }
            QMenu::item:selected {
                background-color: #0066cc;
            }
            QMenu::separator {
                height: 1px;
                background: #555;
                margin: 4px 10px;
            }
        """)

        # Giriş (login) seçeneği
        login_action = QAction("Tahtayı Aç (Giriş)", self)
        login_action.triggered.connect(self.show_login)
        context_menu.addAction(login_action)

        context_menu.addSeparator()

        # Sistem Durumu
        status_action = QAction("Sistem Durumu", self)
        status_action.triggered.connect(self.kiosk_show_system_status)
        context_menu.addAction(status_action)

        context_menu.addSeparator()

        # Tahta Yapılandırması
        board_config_action = QAction("Tahta Yapılandırması", self)
        board_config_action.triggered.connect(self.kiosk_show_board_config)
        context_menu.addAction(board_config_action)

        # Şifre Değiştir
        change_pass_action = QAction("Şifre Değiştir", self)
        change_pass_action.triggered.connect(self.kiosk_show_change_password)
        context_menu.addAction(change_pass_action)

        context_menu.addSeparator()

        # Ekran Klavyesi
        keyboard_action = QAction("Ekran Klavyesi", self)
        keyboard_action.triggered.connect(self.kiosk_show_on_screen_keyboard)
        context_menu.addAction(keyboard_action)

        context_menu.addSeparator()

        # Yeniden başlat
        restart_action = QAction("Yeniden Başlat", self)
        restart_action.triggered.connect(self.kiosk_system_restart)
        context_menu.addAction(restart_action)

        # Kapat
        shutdown_action = QAction("Kapat", self)
        shutdown_action.triggered.connect(self.kiosk_system_shutdown)
        context_menu.addAction(shutdown_action)

        context_menu.addSeparator()

        # Hakkında
        about_action = QAction("Hakkında", self)
        about_action.triggered.connect(self.kiosk_show_about)
        context_menu.addAction(about_action)

        context_menu.exec_(QCursor.pos())

    def kiosk_system_shutdown(self):
        """Kiosk modunda sistemi kapat"""
        import subprocess
        logging.info("Kiosk: Shutdown requested from context menu")
        shutdown_commands = [
            ['sudo', 'poweroff'],
            ['sudo', 'systemctl', 'poweroff'],
            ['sudo', '/sbin/poweroff'],
            ['sudo', 'shutdown', '-h', 'now'],
            ['poweroff'],
        ]
        for cmd in shutdown_commands:
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    QApplication.quit()
                    return
            except:
                continue
        os.system("sudo poweroff || poweroff")
        QApplication.quit()

    def kiosk_system_restart(self):
        """Kiosk modunda sistemi yeniden başlat"""
        import subprocess
        logging.info("Kiosk: Reboot requested from context menu")
        reboot_commands = [
            ['sudo', 'reboot'],
            ['sudo', 'systemctl', 'reboot'],
            ['sudo', '/sbin/reboot'],
            ['reboot'],
        ]
        for cmd in reboot_commands:
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    QApplication.quit()
                    return
            except:
                continue
        os.system("sudo reboot || reboot")
        QApplication.quit()

    def show_login(self):
        """Show admin login dialog - önce keyboard locker'ı durdur ki yazabilsin"""
        # CRITICAL: Keyboard locker'ı durdur ve bitmesini bekle!
        if self.keyboard_locker:
            self.keyboard_locker.stop()
            self.keyboard_locker.join(timeout=3)  # Thread'in bitmesini bekle
            self.keyboard_locker = None
            logging.info("Kiosk: Keyboard locker stopped and joined for login dialog")
            # Kısa bekleme - cihaz grab'ın tamamen serbest kalması için
            import time
            time.sleep(0.5)

        dialog = QDialog(self)
        dialog.setWindowTitle("Yönetici Girişi")
        dialog.setModal(True)
        dialog.setWindowFlags(Qt.WindowStaysOnTopHint | Qt.Dialog)

        # Dialog stil ve boyut ayarları - kiosk fullscreen'de düzgün görünsün
        dialog.setStyleSheet("""
            QDialog {
                background-color: #2b2b2b;
                color: white;
                border: 2px solid #0066cc;
                border-radius: 10px;
            }
            QLabel {
                color: white;
            }
            QLineEdit {
                background-color: #3c3c3c;
                color: white;
                border: 2px solid #555;
                border-radius: 5px;
                padding: 10px;
                font-size: 16px;
            }
            QLineEdit:focus {
                border-color: #0066cc;
            }
            QPushButton {
                padding: 10px 20px;
                border-radius: 5px;
                font-size: 14px;
                font-weight: bold;
                min-width: 120px;
            }
        """)

        layout = QVBoxLayout()
        layout.setSpacing(15)
        layout.setContentsMargins(30, 25, 30, 25)

        title = QLabel("Sistem Kilidi Açma")
        title.setFont(QFont("Arial", 20, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("color: white; margin-bottom: 5px;")
        layout.addWidget(title)

        # Info label: show password hint
        info = QLabel("Mebrecep uygulamasından şifreyi alın\nveya metin kutusuna tıklayarak ekran klavyesini açın")
        info.setAlignment(Qt.AlignCenter)
        info.setStyleSheet("color: #aaa; font-size: 13px; margin-bottom: 10px;")
        info.setWordWrap(True)
        layout.addWidget(info)

        password_field = KeyboardLineEdit()
        password_field.setEchoMode(QLineEdit.Password)
        password_field.setPlaceholderText("Mebrecep'ten şifre yazınız")
        password_field.setFont(QFont("Arial", 16))
        password_field.setMinimumHeight(50)
        layout.addWidget(password_field)

        button_layout = QHBoxLayout()
        button_layout.setSpacing(15)

        cancel_btn = QPushButton("İptal")
        cancel_btn.setMinimumHeight(50)
        cancel_btn.setStyleSheet("background-color: #555; color: white; font-weight: bold;")
        cancel_btn.clicked.connect(dialog.reject)
        button_layout.addWidget(cancel_btn)

        login_btn = QPushButton("Giriş")
        login_btn.setMinimumHeight(50)
        login_btn.setStyleSheet("background-color: #0066cc; color: white; font-weight: bold;")
        login_btn.clicked.connect(lambda: self.attempt_unlock(password_field.text(), dialog))
        login_btn.setDefault(True)
        button_layout.addWidget(login_btn)

        layout.addLayout(button_layout)
        dialog.setLayout(layout)

        # Boyut ve konum ayarları
        dialog.setFixedSize(450, 320)
        # Ekranın ortasına yerleştir
        screen = QApplication.primaryScreen().geometry()
        dialog.move(
            (screen.width() - 450) // 2,
            (screen.height() - 320) // 2
        )

        logging.info("Kiosk: Login dialog shown")
        result = dialog.exec()
        logging.info(f"Kiosk: Login dialog closed with result={result}")

        # Dialog kapandıysa ve kilit açılmadıysa keyboard locker'ı tekrar başlat
        if result != QDialog.Accepted:
            self.keyboard_locker = KeyboardLocker()
            self.keyboard_locker.start()
            logging.info("Kiosk: Keyboard locker restarted after cancelled login")

    def attempt_unlock(self, password, dialog):
        """
        Kiosk modunda şifre ile kilit açma
        Mebrecep'ten alınan dinamik şifre ile çalışır
        """
        logging.info(f"Kiosk: Unlock attempt with password length={len(password)}")
        
        if not password or len(password) == 0:
            QMessageBox.warning(dialog, "Hata", "Lütfen şifre giriniz!")
            return
        
        # Dinamik şifre kontrolü (C# pctrl.pc() karşılığı)
        if validate_dynamic_password(password):
            logging.info("Kiosk mode unlocked with dynamic password (Mebrecep)")
            dialog.accept()
            self.unlock_and_exit()
        else:
            # Show what the expected password would be for debugging
            from datetime import datetime as dt_class
            now = dt_class.now()
            expected = generate_dynamic_password(now, 0)
            logging.warning(f"Failed kiosk unlock attempt - entered len={len(password)}, expected={expected}")
            QMessageBox.warning(dialog, "Hata", "Yanlış şifre!\nMebrecep uygulamasından güncel şifreyi alın.")

    def unlock_and_exit(self):
        """Unlock and exit to allow real user login"""
        logging.info("Kiosk mode unlock successful - exiting to show user login")

        # Stop USB timer
        if self.usb_timer:
            self.usb_timer.stop()

        # Stop server polling timer
        if self.server_timer:
            self.server_timer.stop()

        # Stop time timer
        if self.time_timer:
            self.time_timer.stop()

        # Stop keyboard locker
        if self.keyboard_locker:
            self.keyboard_locker.stop()
            self.keyboard_locker = None

        # Hide window
        self.hide()

        # Exit application - kiosk launcher will restart display manager
        QApplication.quit()

    def kiosk_show_system_status(self):
        """Kiosk modunda sistem durumu göster"""
        board_name = SETTINGS.get('board_name', 'Akıllı Tahta')
        status_text = f"""
Sistem Durumu:

Tahta Adı: {board_name}
Versiyon: {SETTINGS.get('version')}.{SETTINGS.get('sub_version')}
Sistem Kilidi: Aktif (Kiosk Modu)
USB Bağlı: {'Evet' if check_usb_password() else 'Hayır'}
Ağ Bağlantısı: {'Var' if self.network_client.check_network() else 'Yok'}
_________________________________________________________________________________________
"""
        QMessageBox.information(self, "Sistem Durumu", status_text.strip())

    def kiosk_show_board_config(self):
        """Kiosk modunda tahta yapılandırması göster"""
        config_dialog = BoardConfigDialog(self, network_client=self.network_client)
        config_dialog.exec()

    def kiosk_show_change_password(self):
        """Kiosk modunda şifre değiştir dialog göster"""
        change_dialog = ChangePasswordDialog(self)
        change_dialog.exec()

    def kiosk_show_on_screen_keyboard(self):
        """Kiosk modunda ekran klavyesi göster"""
        keyboard = OnScreenKeyboard()
        keyboard.exec()

    def kiosk_show_about(self):
        """Kiosk modunda hakkında dialog göster"""
        about_text = f"""
Fatih Akıllı Tahta İstemcisi

Versiyon: {SETTINGS.get('version')}.{SETTINGS.get('sub_version')}

Bu yazılım Fatih Projesi kapsamında geliştirilmiştir.
Akıllı tahta güvenliği ve yönetimi için tasarlanmıştır.
"""
        QMessageBox.about(self, "Hakkında", about_text.strip())

    def resizeEvent(self, event):
        """Handle window resize to reposition UI elements"""
        super().resizeEvent(event)

        if hasattr(self, 'background'):
            self.background.setGeometry(self.rect())

        if hasattr(self, 'login_button'):
            screen_center_x = self.width() // 2
            screen_center_y = self.height() // 2
            button_width = 280
            button_height = 60
            self.login_button.move(screen_center_x - button_width // 2, screen_center_y + 80)

        if hasattr(self, 'message_label'):
            self.message_label.setGeometry(50, self.height() // 2 - 100, self.width() - 100, 200)

        if hasattr(self, 'time_label'):
            self.time_label.setGeometry(self.width() - 250, self.height() - 50, 240, 40)

        if hasattr(self, 'board_id_label'):
            label_width = 450
            label_x = (self.width() - label_width) // 2
            self.board_id_label.setGeometry(label_x, 20, label_width, 100)

if __name__ == '__main__':
    # Check command line arguments
    if len(sys.argv) > 1:
        if sys.argv[1] == '--test':
            print("Running in test mode...")
            try:
                validate_config()
                print("✅ Configuration loaded successfully")
                print(f"Admin password: {SETTINGS.get('admin_password', 'mebre')}")
            except Exception as e:
                print(f"❌ Configuration error: {e}")
            sys.exit(0)
        elif sys.argv[1] == '--kiosk':
            print("Running in KIOSK mode (pre-login lock screen)")
            main_kiosk()
            sys.exit(0)

    # Normal mode
    main()


"""
platform_layer.py — İşletim sistemi ZORLAMA katmanı (kiosk/kilit uygulaması).

Amaç: Pardus (Linux) ve Windows aynı client.py'yi paylaşır. Özellik/ağ/UI katmanı
cross-platform (PyQt5). Ancak "zorlama" — taskbar gizleme, ses, kısayol kilidi, uyku
engeli, ön uygulamaları kapatma — işletim sistemine özeldir. Bu modül o farkı bir
ARAYÜZ (PlatformBackend) arkasına alır:

  - LinuxBackend  : mevcut Pardus mantığı (gsettings/xdotool/pactl/wmctrl/xset/pkill).
  - WindowsBackend: şimdilik NO-OP (W6-2'de Win32 ile doldurulacak).

client.py bu modülü çağırır (`get_platform()`); nerede çalıştığını bilmesine gerek yok.

W6-1 kapsamı: kiosk zorlama (8 metot). Klavye grab (evdev), USB izleme (pyudev),
autostart, kaldırma HALEN client.py'de (W6-0'da guard'lı); ileri adımda buraya taşınır.
"""

import sys
import os
import platform as _platform
import logging
import subprocess as _subprocess

IS_WINDOWS = _platform.system() == 'Windows'
IS_LINUX = _platform.system() == 'Linux'

# client.py ile AYNI: geliştirme modunda zorlama atlanır.
NO_LOCK_MODE = '--no-lock' in sys.argv


def detect_desktop_environment() -> str:
    """Çalışma zamanında masaüstü ortamını algıla (Linux). Windows'ta 'WINDOWS' döner."""
    if IS_WINDOWS:
        return 'WINDOWS'
    desktop = os.environ.get('XDG_CURRENT_DESKTOP', '').upper()
    session = os.environ.get('DESKTOP_SESSION', '').upper()
    if 'GNOME' in desktop or 'GNOME' in session:
        return 'GNOME'
    elif 'XFCE' in desktop or 'XFCE' in session:
        return 'XFCE'
    elif 'CINNAMON' in desktop or 'CINNAMON' in session:
        return 'CINNAMON'
    elif 'KDE' in desktop or 'KDE' in session:
        return 'KDE'
    try:
        if _subprocess.run(['pgrep', '-x', 'gnome-shell'], capture_output=True).returncode == 0:
            return 'GNOME'
        if _subprocess.run(['pgrep', '-x', 'xfce4-panel'], capture_output=True).returncode == 0:
            return 'XFCE'
    except Exception:
        pass
    return 'UNKNOWN'


DESKTOP_ENV = detect_desktop_environment()


class PlatformBackend:
    """Zorlama arayüzü. Alt sınıflar (Linux/Windows) bu metotları uygular.

    Varsayılan gövdeler NO-OP'tur; bir platform bir metodu uygulamazsa sessizce geçer
    (tahtayı kilitte bırakmaktan iyidir — fail-safe UI tarafında zaten var).
    """

    name = 'base'

    # --- Kiosk zorlama ---
    def hide_taskbar(self):
        """Görev çubuğunu/paneli gizle (kilitlenince)."""
        pass

    def show_taskbar(self):
        """Görev çubuğunu/paneli geri göster (kilit açılınca)."""
        pass

    def mute(self):
        """Sesi kapat (kilitlenince)."""
        pass

    def unmute(self):
        """Sesi aç + duyulur seviyeye getir (kilit açılınca)."""
        pass

    def disable_sleep(self):
        """Uyku/ekran kapanması/ekran koruyucuyu devre dışı bırak."""
        pass

    def disable_shortcuts(self):
        """Tehlikeli klavye kısayollarını devre dışı bırak (kilitlenince)."""
        pass

    def restore_shortcuts(self):
        """Kısayolları geri yükle (kilit açılınca)."""
        pass

    def kill_foreground_apps(self):
        """Tarayıcılar + görev yöneticisi gibi kilidi atlayabilecek uygulamaları kapat."""
        pass


class LinuxBackend(PlatformBackend):
    """Pardus/Linux zorlama — mevcut client.py mantığı (davranış birebir korunur)."""

    name = 'linux'

    def __init__(self):
        self._saved_shortcuts = {}

    def hide_taskbar(self):
        if NO_LOCK_MODE:
            logging.info("[NO-LOCK] hide_taskbar() skipped")
            return
        try:
            de = DESKTOP_ENV
            if de == 'GNOME':
                for cmd in (
                    ['gsettings', 'set', 'org.gnome.shell.extensions.dash-to-dock', 'dock-fixed', 'false'],
                    ['gsettings', 'set', 'org.gnome.shell.extensions.dash-to-dock', 'autohide', 'true'],
                    ['gsettings', 'set', 'org.gnome.shell.extensions.dash-to-dock', 'intellihide', 'false'],
                ):
                    try: _subprocess.run(cmd, capture_output=True, timeout=3)
                    except Exception: pass
                try:
                    _subprocess.run(['gdbus', 'call', '--session', '--dest', 'org.gnome.Shell',
                                     '--object-path', '/org/gnome/Shell', '--method', 'org.gnome.Shell.Eval',
                                     'Main.panel.hide();'], capture_output=True, timeout=3)
                except Exception: pass
            elif de == 'XFCE':
                try:
                    _subprocess.run(['xfconf-query', '-c', 'xfce4-panel', '-p',
                                     '/panels/panel-1/autohide-behavior', '-s', '2'], capture_output=True, timeout=3)
                except Exception: pass
            elif de == 'CINNAMON':
                try:
                    _subprocess.run(['gsettings', 'set', 'org.cinnamon', 'panels-autohide', "['1:true']"],
                                    capture_output=True, timeout=3)
                except Exception: pass
                try:
                    result = _subprocess.run(['xdotool', 'search', '--name', 'Cinnamon'],
                                             capture_output=True, text=True, timeout=3)
                    for wid in result.stdout.strip().split():
                        _subprocess.run(['xdotool', 'windowminimize', wid], capture_output=True, timeout=2)
                except Exception: pass
                try:
                    _subprocess.run(['wmctrl', '-r', ':ACTIVE:', '-b', 'add,below'], capture_output=True, timeout=2)
                except Exception: pass
            logging.info(f"Panel hidden ({de})")
        except Exception as e:
            logging.error(f"Error hiding panel: {e}")

    def show_taskbar(self):
        try:
            de = DESKTOP_ENV
            if de == 'GNOME':
                for cmd in (
                    ['gsettings', 'set', 'org.gnome.shell.extensions.dash-to-dock', 'dock-fixed', 'true'],
                    ['gsettings', 'set', 'org.gnome.shell.extensions.dash-to-dock', 'autohide', 'false'],
                ):
                    try: _subprocess.run(cmd, capture_output=True, timeout=3)
                    except Exception: pass
                try:
                    _subprocess.run(['gdbus', 'call', '--session', '--dest', 'org.gnome.Shell',
                                     '--object-path', '/org/gnome/Shell', '--method', 'org.gnome.Shell.Eval',
                                     'Main.panel.show();'], capture_output=True, timeout=3)
                except Exception: pass
            elif de == 'XFCE':
                try:
                    _subprocess.run(['xfconf-query', '-c', 'xfce4-panel', '-p',
                                     '/panels/panel-1/autohide-behavior', '-s', '0'], capture_output=True, timeout=3)
                except Exception: pass
            elif de == 'CINNAMON':
                try:
                    _subprocess.run(['gsettings', 'set', 'org.cinnamon', 'panels-autohide', "['1:false']"],
                                    capture_output=True, timeout=3)
                except Exception: pass
            logging.info(f"Panel shown ({de})")
        except Exception as e:
            logging.error(f"Error showing panel: {e}")

    def mute(self):
        try:
            for cmd in (['pactl', 'set-sink-mute', '@DEFAULT_SINK@', '1'],
                        ['amixer', 'set', 'Master', 'mute']):
                try:
                    if _subprocess.run(cmd, capture_output=True, timeout=3).returncode == 0:
                        logging.info(f"Audio muted using {cmd[0]}")
                        return
                except FileNotFoundError:
                    continue
                except Exception:
                    continue
        except Exception as e:
            logging.error(f"Error muting audio: {e}")

    def unmute(self):
        try:
            for cmd in (['pactl', 'set-sink-mute', '@DEFAULT_SINK@', '0'],
                        ['amixer', 'set', 'Master', 'unmute']):
                try:
                    if _subprocess.run(cmd, capture_output=True, timeout=3).returncode == 0:
                        logging.info(f"Audio unmuted using {cmd[0]}")
                        break
                except (FileNotFoundError, Exception):
                    continue
            for cmd in (['pactl', 'set-sink-volume', '@DEFAULT_SINK@', '100%'],
                        ['amixer', 'set', 'Master', '100%']):
                try:
                    if _subprocess.run(cmd, capture_output=True, timeout=3).returncode == 0:
                        logging.info(f"Volume set to max using {cmd[0]}")
                        break
                except (FileNotFoundError, Exception):
                    continue
        except Exception as e:
            logging.error(f"Error unmuting audio: {e}")

    def disable_sleep(self):
        try:
            de = DESKTOP_ENV
            if de == 'GNOME':
                for cmd in (
                    ['gsettings', 'set', 'org.gnome.settings-daemon.plugins.power', 'sleep-inactive-ac-type', 'nothing'],
                    ['gsettings', 'set', 'org.gnome.settings-daemon.plugins.power', 'sleep-inactive-battery-type', 'nothing'],
                    ['gsettings', 'set', 'org.gnome.desktop.session', 'idle-delay', '0'],
                    ['gsettings', 'set', 'org.gnome.desktop.screensaver', 'lock-enabled', 'false'],
                ):
                    try: _subprocess.run(cmd, capture_output=True, timeout=3)
                    except Exception: pass
            elif de == 'XFCE':
                for cmd in (
                    ['xfconf-query', '-c', 'xfce4-power-manager', '-p', '/xfce4-power-manager/inactivity-on-ac', '-s', '0'],
                    ['xfconf-query', '-c', 'xfce4-power-manager', '-p', '/xfce4-power-manager/dpms-enabled', '-s', 'false'],
                ):
                    try: _subprocess.run(cmd, capture_output=True, timeout=3)
                    except Exception: pass
            try:
                _subprocess.run(['xset', 's', 'off'], capture_output=True, timeout=3)
                _subprocess.run(['xset', '-dpms'], capture_output=True, timeout=3)
                _subprocess.run(['xset', 's', 'noblank'], capture_output=True, timeout=3)
            except Exception: pass
            logging.info(f"Sleep mode disabled ({de})")
        except Exception as e:
            logging.error(f"Error disabling sleep: {e}")

    def disable_shortcuts(self):
        if NO_LOCK_MODE:
            logging.info("[NO-LOCK] disable_shortcuts() skipped")
            return
        try:
            de = DESKTOP_ENV
            if de == 'GNOME':
                shortcuts_to_disable = {
                    'org.gnome.mutter overlay-key': "''",
                    'org.gnome.settings-daemon.plugins.media-keys logout': "''",
                    'org.gnome.desktop.wm.keybindings switch-to-workspace-up': "'[]'",
                    'org.gnome.desktop.wm.keybindings switch-to-workspace-down': "'[]'",
                    'org.gnome.desktop.wm.keybindings panel-main-menu': "'[]'",
                }
                for key, disable_val in shortcuts_to_disable.items():
                    schema, prop = key.rsplit(' ', 1)
                    try:
                        result = _subprocess.run(['gsettings', 'get', schema, prop],
                                                 capture_output=True, text=True, timeout=3)
                        if result.returncode == 0:
                            self._saved_shortcuts[key] = result.stdout.strip()
                        _subprocess.run(['gsettings', 'set', schema, prop, disable_val],
                                        capture_output=True, timeout=3)
                    except Exception: pass
            elif de == 'XFCE':
                try:
                    _subprocess.run(['xfconf-query', '-c', 'xfce4-keyboard-shortcuts', '-p',
                                     '/commands/custom/super', '-s', ''], capture_output=True, timeout=3)
                except Exception: pass
            try:
                _subprocess.run(['sudo', 'systemctl', 'mask', 'ctrl-alt-del.target'], capture_output=True, timeout=3)
            except Exception: pass
            logging.info(f"Keyboard shortcuts disabled ({de})")
        except Exception as e:
            logging.error(f"Error disabling shortcuts: {e}")

    def restore_shortcuts(self):
        try:
            de = DESKTOP_ENV
            if de == 'GNOME':
                for key, original_val in self._saved_shortcuts.items():
                    schema, prop = key.rsplit(' ', 1)
                    try:
                        _subprocess.run(['gsettings', 'set', schema, prop, original_val],
                                        capture_output=True, timeout=3)
                    except Exception: pass
                self._saved_shortcuts.clear()
            try:
                _subprocess.run(['sudo', 'systemctl', 'unmask', 'ctrl-alt-del.target'], capture_output=True, timeout=3)
            except Exception: pass
            logging.info(f"Keyboard shortcuts restored ({de})")
        except Exception as e:
            logging.error(f"Error restoring shortcuts: {e}")

    def kill_foreground_apps(self):
        targets = [
            'chromium', 'chromium-browser', 'firefox', 'firefox-esr',
            'google-chrome', 'opera', 'midori', 'epiphany',
            'gnome-system-monitor', 'xfce4-taskmanager',
        ]
        for target in targets:
            try:
                _subprocess.run(['pkill', '-f', target], capture_output=True, timeout=3)
            except Exception:
                pass
        logging.info("All browsers and monitors killed")


class WindowsBackend(PlatformBackend):
    """Windows zorlama — W6-2'de Win32 ile doldurulacak. Şimdilik NO-OP (güvenli).

    Yol haritası (W6-2):
      hide/show_taskbar  -> Shell_TrayWnd'i SetWindowPos ile gizle/göster
      mute/unmute        -> Core Audio (pycaw) veya nircmd
      disable_sleep      -> SetThreadExecutionState(ES_CONTINUOUS|ES_DISPLAY_REQUIRED)
      disable_shortcuts  -> low-level keyboard hook (Task Manager/Alt+Tab/Win engel)
      kill_foreground    -> taskkill /IM chrome.exe ... (dikkatli hedef listesi)
    """

    name = 'windows'

    def __init__(self):
        logging.info("WindowsBackend: kiosk zorlaması henüz NO-OP (W6-2'de gelecek).")

    # Tüm metotlar PlatformBackend'deki no-op'ları miras alır (pass).


_INSTANCE = None


def get_platform() -> PlatformBackend:
    """Tekil (singleton) platform backend'i döndürür."""
    global _INSTANCE
    if _INSTANCE is None:
        _INSTANCE = WindowsBackend() if IS_WINDOWS else LinuxBackend()
        logging.info(f"Platform backend: {_INSTANCE.name} (DESKTOP_ENV={DESKTOP_ENV})")
    return _INSTANCE

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
import threading
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

    def disable_shortcuts(self, auto_release_sec=None, panic_cb=None):
        """Tehlikeli klavye kısayollarını devre dışı bırak (kilitlenince).
        auto_release_sec: test için N sn sonra otomatik bırak (platform destekliyorsa).
        panic_cb: panik kombinasyonunda (Ctrl+Alt+Shift+Q) çağrılır — verilirse hook
        BIRAKILMAZ, karar üst katmanındır (şifre sorma vb.); None ise eski davranış (bırak)."""
        pass

    def restore_shortcuts(self):
        """Kısayolları geri yükle (kilit açılınca)."""
        pass

    def kill_foreground_apps(self):
        """Tarayıcılar + görev yöneticisi gibi kilidi atlayabilecek uygulamaları kapat."""
        pass

    def force_window_on_top(self, hwnd):
        """Verilen pencereyi en üste zorla (kilit ekranı masaüstünü örtsün). Linux'ta
        çağıran taraf (client._force_on_top) xdotool kullanır; bu metot Windows içindir."""
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

    def disable_shortcuts(self, auto_release_sec=None, panic_cb=None):
        # panic_cb Linux'ta kullanılmaz: fiziksel klavye evdev ile grab'lidir, kombinasyon
        # dinlenmez (panik çıkışın Linux karşılığı: sağ tık menüsü + admin şifresi).
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


if IS_WINDOWS:
    import ctypes
    from ctypes import wintypes

    class _WindowsKeyboardLock:
        """Windows low-level klavye hook'u ile kilit-atlatma tuşlarını engeller.

        Engellenen: Win tuşu, Alt+Tab, Alt+Esc, Ctrl+Esc, Alt+F4, Ctrl+Shift+Esc (Görev Yön.).
        Engellenemez (kernel/güvenlik): Ctrl+Alt+Del (Secure Attention Sequence) — bu KASITLI
        nihai kaçış: makine asla kalıcı kilitlenmez.

        GÜVENLİK:
          - PANİK: Ctrl+Alt+Shift+Q → hook anında bırakılır.
          - Opsiyonel auto_release_sec → N sn sonra kendini bırakır (test için şart).
        Hook, kendi mesaj döngülü ayrı thread'de kurulur (GUI'yi bloklamaz).
        """

        WH_KEYBOARD_LL = 13
        WM_QUIT = 0x0012
        HC_ACTION = 0
        VK_TAB, VK_ESCAPE, VK_F4 = 0x09, 0x1B, 0x73
        VK_LWIN, VK_RWIN = 0x5B, 0x5C
        VK_CONTROL, VK_MENU, VK_SHIFT = 0x11, 0x12, 0x10
        PANIC_VK = 0x51  # 'Q'

        class _KBD(ctypes.Structure):
            _fields_ = [("vkCode", wintypes.DWORD), ("scanCode", wintypes.DWORD),
                        ("flags", wintypes.DWORD), ("time", wintypes.DWORD),
                        ("dwExtraInfo", ctypes.c_void_p)]

        def __init__(self):
            self._user32 = ctypes.windll.user32
            self._kernel32 = ctypes.windll.kernel32

            # KRİTİK (x64): argtype/restype tanımla, yoksa ctypes 64-bit pointer'ları
            # (modül handle, callback, hook handle, LRESULT) 32-bit'e KIRPAR ve hook kurulmaz.
            self._PROC = ctypes.CFUNCTYPE(ctypes.c_ssize_t, ctypes.c_int,
                                          wintypes.WPARAM, wintypes.LPARAM)
            u = self._user32
            k = self._kernel32
            u.SetWindowsHookExW.argtypes = [ctypes.c_int, self._PROC, ctypes.c_void_p, wintypes.DWORD]
            u.SetWindowsHookExW.restype = ctypes.c_void_p
            u.CallNextHookEx.argtypes = [ctypes.c_void_p, ctypes.c_int, wintypes.WPARAM, wintypes.LPARAM]
            u.CallNextHookEx.restype = ctypes.c_ssize_t
            u.UnhookWindowsHookEx.argtypes = [ctypes.c_void_p]
            u.UnhookWindowsHookEx.restype = wintypes.BOOL
            u.GetMessageW.argtypes = [ctypes.POINTER(wintypes.MSG), ctypes.c_void_p, wintypes.UINT, wintypes.UINT]
            u.GetMessageW.restype = ctypes.c_int
            u.TranslateMessage.argtypes = [ctypes.POINTER(wintypes.MSG)]
            u.DispatchMessageW.argtypes = [ctypes.POINTER(wintypes.MSG)]
            u.PostThreadMessageW.argtypes = [wintypes.DWORD, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM]
            u.PostThreadMessageW.restype = wintypes.BOOL
            u.GetAsyncKeyState.argtypes = [ctypes.c_int]
            u.GetAsyncKeyState.restype = wintypes.SHORT
            k.GetModuleHandleW.argtypes = [wintypes.LPCWSTR]
            k.GetModuleHandleW.restype = ctypes.c_void_p
            k.GetCurrentThreadId.restype = wintypes.DWORD

            self._callback_ref = self._PROC(self._callback)  # GC'lenmesin diye tut
            self._hook = None
            self._thread = None
            self._thread_id = None
            self._auto_timer = None

        def _down(self, vk):
            return bool(self._user32.GetAsyncKeyState(vk) & 0x8000)

        def _callback(self, nCode, wParam, lParam):
            try:
                if nCode == self.HC_ACTION:
                    kbd = ctypes.cast(lParam, ctypes.POINTER(self._KBD)).contents
                    vk = kbd.vkCode
                    ctrl = self._down(self.VK_CONTROL)
                    alt = self._down(self.VK_MENU)
                    shift = self._down(self.VK_SHIFT)

                    # PANİK: Ctrl+Alt+Shift+Q. panic_cb varsa hook BIRAKILMAZ — üst katman
                    # (istemci) şifre sorup karar verir; yoksa eski davranış: kilidi bırak.
                    if vk == self.PANIC_VK and ctrl and alt and shift:
                        cb = getattr(self, '_panic_cb', None)
                        if cb:
                            logging.info("PANİK kombinasyonu — istemciye devrediliyor (şifre sorulacak).")
                            try:
                                threading.Thread(target=cb, daemon=True).start()
                            except Exception as e:
                                logging.error(f"panic_cb çağrılamadı: {e}")
                            return 1
                        logging.info("PANİK: klavye kilidi bırakılıyor (Ctrl+Alt+Shift+Q)")
                        self.stop()
                        return 1

                    block = (
                        vk in (self.VK_LWIN, self.VK_RWIN)          # Win tuşu
                        or (vk == self.VK_TAB and alt)              # Alt+Tab
                        or (vk == self.VK_ESCAPE and (alt or ctrl)) # Alt+Esc / Ctrl+Esc (+Ctrl+Shift+Esc)
                        or (vk == self.VK_F4 and alt)               # Alt+F4
                    )
                    if block:
                        return 1  # yut
            except Exception:
                pass
            return self._user32.CallNextHookEx(None, nCode, wParam, lParam)

        def _thread_proc(self):
            self._thread_id = self._kernel32.GetCurrentThreadId()
            hmod = self._kernel32.GetModuleHandleW(None)
            self._hook = self._user32.SetWindowsHookExW(
                self.WH_KEYBOARD_LL, self._callback_ref, hmod, 0)
            if not self._hook:
                err = ctypes.get_last_error() if hasattr(ctypes, 'get_last_error') else self._kernel32.GetLastError()
                logging.error(f"SetWindowsHookExW başarısız (GetLastError={err}) — klavye kilidi kurulamadı.")
                return
            logging.info("Klavye kilidi AKTİF (Win/Alt+Tab/Alt+Esc/Ctrl+Esc/Alt+F4 engelli). "
                         "Panik: Ctrl+Alt+Shift+Q. Ctrl+Alt+Del her zaman çalışır.")
            msg = wintypes.MSG()
            while self._user32.GetMessageW(ctypes.byref(msg), None, 0, 0) > 0:
                self._user32.TranslateMessage(ctypes.byref(msg))
                self._user32.DispatchMessageW(ctypes.byref(msg))
            if self._hook:
                self._user32.UnhookWindowsHookEx(self._hook)
                self._hook = None
            logging.info("Klavye kilidi bırakıldı.")

        def start(self, auto_release_sec=None, panic_cb=None):
            self._panic_cb = panic_cb
            if self._thread and self._thread.is_alive():
                return
            self._thread = threading.Thread(target=self._thread_proc, daemon=True)
            self._thread.start()
            if auto_release_sec:
                self._auto_timer = threading.Timer(auto_release_sec, self.stop)
                self._auto_timer.daemon = True
                self._auto_timer.start()

        def stop(self):
            if self._auto_timer:
                try: self._auto_timer.cancel()
                except Exception: pass
                self._auto_timer = None
            if self._thread_id:
                self._user32.PostThreadMessageW(self._thread_id, self.WM_QUIT, 0, 0)
                self._thread_id = None


class WindowsBackend(PlatformBackend):
    """Windows zorlama (W6-2). Güvenli primitifler ctypes/pycaw ile.

    UYGULANDI (geri alınabilir, kilitlemez):
      hide/show_taskbar -> Shell_TrayWnd + Start düğmesi ShowWindow(HIDE/SHOW)
      disable_sleep     -> SetThreadExecutionState(ES_CONTINUOUS|SYSTEM|DISPLAY)
      mute/unmute       -> Core Audio (pycaw); yoksa NO-OP
      kill_foreground   -> taskkill /F /IM (tarayıcılar + görev yöneticisi)

    ⚠ HENÜZ NO-OP — TEHLİKELİ, ayrı+dikkatli adım (Faz W6-2B):
      disable/restore_shortcuts -> low-level keyboard hook (Ctrl+Alt+Del/Alt+Tab/Win/
      Task Manager engeli). Yanlış yaparsak makineyi kilitler; panik-çıkış + gerçek
      kiosk modu şartıyla yazılacak. Şimdilik BİLEREK boş.
    """

    name = 'windows'

    ES_CONTINUOUS = 0x80000000
    ES_SYSTEM_REQUIRED = 0x00000001
    ES_DISPLAY_REQUIRED = 0x00000002
    SW_HIDE = 0
    SW_SHOW = 5

    def __init__(self):
        import ctypes
        self._ctypes = ctypes
        self._user32 = ctypes.windll.user32
        self._kernel32 = ctypes.windll.kernel32
        # SetWindowPos: pencereyi HWND_TOPMOST yap (x64 prototip şart).
        self._user32.SetWindowPos.argtypes = [ctypes.c_void_p, ctypes.c_void_p,
                                              ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                                              wintypes.UINT]
        self._user32.SetWindowPos.restype = wintypes.BOOL
        self._keylock = _WindowsKeyboardLock()
        # Ses: pycaw varsa kullan, yoksa ses no-op (kurulum bagimliligini zorlamayalim).
        self._audio = None
        try:
            from ctypes import cast, POINTER
            from comtypes import CLSCTX_ALL
            from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
            self._pycaw = (cast, POINTER, CLSCTX_ALL, AudioUtilities, IAudioEndpointVolume)
            logging.info("WindowsBackend: pycaw bulundu (ses kontrolu aktif).")
        except Exception:
            self._pycaw = None
            logging.info("WindowsBackend: pycaw yok -> ses kontrolu NO-OP (pip install pycaw).")

    # --- Taskbar ---
    def _taskbar_windows(self):
        wins = []
        tray = self._user32.FindWindowW("Shell_TrayWnd", None)
        if tray:
            wins.append(tray)
        # Cok monitorlu: ikincil gorev cubuklari
        sec = self._user32.FindWindowW("Shell_SecondaryTrayWnd", None)
        if sec:
            wins.append(sec)
        # Eski Windows'ta ayri Baslat dugmesi
        start = self._user32.FindWindowW("Button", None)
        if start:
            wins.append(start)
        return wins

    def hide_taskbar(self):
        if NO_LOCK_MODE:
            logging.info("[NO-LOCK] hide_taskbar() skipped")
            return
        try:
            for w in self._taskbar_windows():
                self._user32.ShowWindow(w, self.SW_HIDE)
            logging.info("Taskbar hidden (Windows)")
        except Exception as e:
            logging.error(f"Error hiding taskbar (Windows): {e}")

    def show_taskbar(self):
        try:
            for w in self._taskbar_windows():
                self._user32.ShowWindow(w, self.SW_SHOW)
            logging.info("Taskbar shown (Windows)")
        except Exception as e:
            logging.error(f"Error showing taskbar (Windows): {e}")

    # --- Uyku ---
    def disable_sleep(self):
        try:
            self._kernel32.SetThreadExecutionState(
                self.ES_CONTINUOUS | self.ES_SYSTEM_REQUIRED | self.ES_DISPLAY_REQUIRED)
            logging.info("Sleep/display disabled (Windows)")
        except Exception as e:
            logging.error(f"Error disabling sleep (Windows): {e}")

    def _volume_iface(self):
        cast, POINTER, CLSCTX_ALL, AudioUtilities, IAudioEndpointVolume = self._pycaw
        devices = AudioUtilities.GetSpeakers()
        interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        return cast(interface, POINTER(IAudioEndpointVolume))

    def mute(self):
        if not self._pycaw:
            return
        try:
            self._volume_iface().SetMute(1, None)
            logging.info("Audio muted (Windows/pycaw)")
        except Exception as e:
            logging.error(f"Error muting audio (Windows): {e}")

    def unmute(self):
        if not self._pycaw:
            return
        try:
            vol = self._volume_iface()
            vol.SetMute(0, None)
            vol.SetMasterVolumeLevelScalar(1.0, None)
            logging.info("Audio unmuted + max (Windows/pycaw)")
        except Exception as e:
            logging.error(f"Error unmuting audio (Windows): {e}")

    # --- On uygulamalar ---
    def kill_foreground_apps(self):
        import subprocess as sp
        targets = ['chrome.exe', 'msedge.exe', 'firefox.exe', 'opera.exe',
                   'iexplore.exe', 'brave.exe', 'taskmgr.exe']
        for t in targets:
            try:
                sp.run(['taskkill', '/F', '/IM', t], capture_output=True, timeout=5)
            except Exception:
                pass
        logging.info("Foreground apps killed (Windows)")

    def force_window_on_top(self, hwnd):
        try:
            c = self._ctypes
            HWND_TOPMOST = c.c_void_p(-1)
            SWP_NOMOVE, SWP_NOSIZE, SWP_SHOWWINDOW = 0x0002, 0x0001, 0x0040
            self._user32.SetWindowPos(c.c_void_p(int(hwnd)), HWND_TOPMOST, 0, 0, 0, 0,
                                      SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW)
        except Exception as e:
            logging.error(f"force_window_on_top (Windows) error: {e}")

    # --- DOKUNMATIK KABUK HAREKETLERI (19 Eyl 2026 — "bücür" videosu) ---
    # Ogrenci klavye kullanmadi: ekranin SOL KENARINDAN icerí kaydirarak Windows 11 GOREV
    # GORUNUMU'nu (Masaustu 1/2, "Yeni masaustu", pencere kucuk resimleri) acti; kilit
    # penceresi baska bir sanal masaustune gecilince gorunmez oluyor. WH_KEYBOARD_LL hook'u
    # yalniz KLAVYE olaylarini yutar; dokunmatik kenar/3-4 parmak hareketleri kabuga dogrudan
    # gider. Uc katman: (1) hareketleri ilke ile kapat (asagida), (2) kur.bat ayni ilkeleri
    # HKLM'ye de yazar, (3) kilit boyunca saniyelik nobetci: pencere on planda/mevcut sanal
    # masaustunde degilse geri getir + Gorev Gorunumu/Baslat aciksa ESC ile kapat.
    def harden_touch_gestures(self):
        """Kenar kaydirma (Task View/Bildirim/Baslat) + 3-4 parmak hareketleri KAPALI.
        HKCU ilkesi: kiosk kullanicisi yazabilir, yonetici gerekmez. Idempotent."""
        if NO_LOCK_MODE:
            return
        try:
            import winreg
            # "Allow edge swipe" ilkesi (Kullanici Yapilandirmasi) — Win10/11.
            k = winreg.CreateKeyEx(winreg.HKEY_CURRENT_USER,
                                   r"Software\Policies\Microsoft\Windows\EdgeUI", 0, winreg.KEY_SET_VALUE)
            winreg.SetValueEx(k, "AllowEdgeSwipe", 0, winreg.REG_DWORD, 0)
            winreg.CloseKey(k)
            # Win11 Ayarlar > Dokunmatik > "Uc ve dort parmak dokunma hareketleri" = kapali.
            k = winreg.CreateKeyEx(winreg.HKEY_CURRENT_USER,
                                   r"Software\Microsoft\Wisp\Touch", 0, winreg.KEY_SET_VALUE)
            winreg.SetValueEx(k, "TouchGestureSetting", 0, winreg.REG_DWORD, 0)
            winreg.CloseKey(k)
            logging.info("Dokunmatik kabuk hareketleri kapatildi (EdgeSwipe/3-4 parmak).")
        except Exception as e:
            logging.error(f"harden_touch_gestures hata: {e}")

    # Kabuk pencereleri: Gorev Gorunumu / Baslat / Bildirim merkezi / Arama.
    _KABUK_SINIFLARI = ("MultitaskingViewFrame", "XamlExplorerHostIslandWindow",
                        "Windows.UI.Core.CoreWindow", "Shell_TrayWnd", "Shell_SecondaryTrayWnd",
                        "TaskListThumbnailWnd", "ForegroundStaging")

    def _on_plandaki_sinif(self):
        c = self._ctypes
        h = self._user32.GetForegroundWindow()
        if not h:
            return None, ''
        buf = c.create_unicode_buffer(128)
        self._user32.GetClassNameW(c.c_void_p(h), buf, 128)
        return h, buf.value

    def _mevcut_sanal_masaustunde(self, hwnd):
        """IVirtualDesktopManager.IsWindowOnCurrentVirtualDesktop (belgeli COM arayuzu, ctypes
        ile). Bilinemezse None (eski Windows / COM hatasi) -> nobetci yalniz on-plan kontrolu yapar."""
        c = self._ctypes
        try:
            if getattr(self, '_vdm', None) is None:
                ole32 = c.windll.ole32
                ole32.CoInitialize(None)

                class GUID(c.Structure):
                    _fields_ = [('a', wintypes.DWORD), ('b', wintypes.WORD), ('c', wintypes.WORD),
                                ('d', c.c_ubyte * 8)]

                def _guid(s):
                    import uuid
                    u = uuid.UUID(s).bytes_le
                    return GUID(int.from_bytes(u[0:4], 'little'), int.from_bytes(u[4:6], 'little'),
                                int.from_bytes(u[6:8], 'little'), (c.c_ubyte * 8)(*u[8:16]))
                clsid = _guid('aa509086-5ca9-4c25-8f95-589d3c07b48a')   # CLSID_VirtualDesktopManager
                iid = _guid('a5cd92ff-29be-454c-8d04-d82879fb3f1b')     # IID_IVirtualDesktopManager
                p = c.c_void_p()
                hr = ole32.CoCreateInstance(c.byref(clsid), None, 1, c.byref(iid), c.byref(p))  # INPROC
                if hr != 0 or not p:
                    self._vdm = False
                    return None
                # vtable: [0]QI [1]AddRef [2]Release [3]IsWindowOnCurrentVirtualDesktop [4]GetWindowDesktopId [5]MoveWindowToDesktop
                vtbl = c.cast(c.cast(p, c.POINTER(c.c_void_p))[0], c.POINTER(c.c_void_p))
                FN = c.WINFUNCTYPE(c.c_long, c.c_void_p, c.c_void_p, c.POINTER(wintypes.BOOL))
                self._vdm = (p, FN(vtbl[3]))
            if self._vdm is False:
                return None
            p, fn = self._vdm
            b = wintypes.BOOL(1)
            hr = fn(p, c.c_void_p(int(hwnd)), c.byref(b))
            return bool(b.value) if hr == 0 else None
        except Exception as e:
            logging.debug(f"sanal masaustu kontrolu: {e}")
            self._vdm = False
            return None

    def kiosk_guard_tick(self, hwnd):
        """Kilitliyken saniyede bir: kabuk (Gorev Gorunumu/Baslat) aciksa ESC ile kapat; pencere
        baska sanal masaustunde ya da on planda degilse geri getir. Doner: mudahale edildi mi."""
        if NO_LOCK_MODE:
            return False
        try:
            import os
            c = self._ctypes
            hwnd = int(hwnd)
            mudahale = False
            fg, sinif = self._on_plandaki_sinif()
            # KENDI penceremiz (giris diyalogu, uyari kutusu, ana pencere) on plandaysa dokunma:
            # yoksa her saniye odagi ana pencereye ceker, diyaloglar kullanilamaz olur.
            fg_pid = wintypes.DWORD(0)
            if fg:
                self._user32.GetWindowThreadProcessId(c.c_void_p(fg), c.byref(fg_pid))
            yabanci = bool(fg) and fg_pid.value != os.getpid()
            if yabanci and sinif in self._KABUK_SINIFLARI:
                # Gorev Gorunumu / Baslat acik -> ESC kapatir (kabuk kendi kisayolunu tanir).
                VK_ESCAPE, KEYEVENTF_KEYUP = 0x1B, 0x0002
                self._user32.keybd_event(VK_ESCAPE, 0, 0, 0)
                self._user32.keybd_event(VK_ESCAPE, 0, KEYEVENTF_KEYUP, 0)
                mudahale = True
            burada = self._mevcut_sanal_masaustunde(hwnd)
            if burada is False or yabanci:
                # SwitchToThisWindow pencerenin bulundugu sanal masaustune GECER ve on plana alir
                # (Alt+Tab ile secmenin programatik karsiligi); SetForegroundWindow tek basina
                # baska masaustundeki pencereyi getirmez.
                self._user32.SwitchToThisWindow(c.c_void_p(hwnd), True)
                # ON PLAN KILIDI: arka plandaki surecin SetForegroundWindow'u Windows tarafindan
                # reddedilebilir. Bilinen, GUVENLI cozum: kendi surecimizle bir tus olayi uret
                # (keybd_event ALT) -> "son girdi bizden" sayilir, cagri kabul edilir.
                # AttachThreadInput BILEREK KULLANILMIYOR: karsi is parcacigi mesgulse UI
                # is parcacigimizi kilitler (19 Eyl yerel testte asili kaldi).
                VK_MENU, KEYEVENTF_KEYUP = 0x12, 0x0002
                self._user32.keybd_event(VK_MENU, 0, 0, 0)
                self._user32.keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0)
                self._user32.BringWindowToTop(c.c_void_p(hwnd))
                self._user32.SetForegroundWindow(c.c_void_p(hwnd))
                self.force_window_on_top(hwnd)
                mudahale = True
            if mudahale:
                logging.warning(f"[NOBETCI] kabuk mudahalesi geri alindi (on plan sinifi='{sinif}', "
                                f"masaustunde={burada}, surec={fg_pid.value}).")
                # TANI BILGISI (23 Eyl 2026): ilk surumde kayda yalniz 'surum' yaziliyordu ve
                # 169 tetiklemenin ogrenci girisimi mi yoksa yanlis alarm mi oldugu anlasilmadi.
                # Artik hangi pencere/surec one gecti ve sanal masaustu kontrolu ne dedi, kayda girer.
                # 'gercek_girisim': kabuk penceresi (Gorev Gorunumu/Baslat) ya da BASKA sanal
                # masaustune gecis. Sadece odak kaybi (baska pencere one gecti) rutin sayilir:
                # geri alinir ama kayda dusmez, yoksa gunluk gurultuye boguluyor (23 Eyl: 169).
                return {'mudahale': True, 'sinif': sinif or '?', 'masaustunde': burada,
                        'surec': self._surec_adi(fg_pid.value),
                        'gercek_girisim': bool(sinif in self._KABUK_SINIFLARI or burada is False)}
            return {'mudahale': False}
        except Exception as e:
            logging.debug(f"kiosk_guard_tick hata: {e}")
            return {'mudahale': False}

    def _surec_adi(self, pid):
        """PID -> calistirilabilir adi (explorer.exe vb.). Bulunamazsa ''. Yalniz taniya yarar."""
        try:
            if not pid:
                return ''
            c = self._ctypes
            PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
            h = self._kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, int(pid))
            if not h:
                return ''
            try:
                buf = c.create_unicode_buffer(260)
                boyut = wintypes.DWORD(260)
                if self._kernel32.QueryFullProcessImageNameW(h, 0, buf, c.byref(boyut)):
                    return buf.value.rsplit('\\', 1)[-1][:40]
            finally:
                self._kernel32.CloseHandle(h)
        except Exception:
            pass
        return ''

    def disable_shortcuts(self, auto_release_sec=None, panic_cb=None):
        """Kilit-atlatma tuşlarını engelle (Win/Alt+Tab/Alt+Esc/Ctrl+Esc/Alt+F4).
        Panik: Ctrl+Alt+Shift+Q — panic_cb verilirse hook BIRAKILMAZ, cb çağrılır
        (istemci şifre sorar; 9 Eyl güvenlik kararı). auto_release_sec: test."""
        if NO_LOCK_MODE:
            logging.info("[NO-LOCK] disable_shortcuts() skipped")
            return
        self._keylock.start(auto_release_sec=auto_release_sec, panic_cb=panic_cb)

    def restore_shortcuts(self):
        """Klavye kilidini bırak."""
        self._keylock.stop()


_INSTANCE = None


def get_platform() -> PlatformBackend:
    """Tekil (singleton) platform backend'i döndürür."""
    global _INSTANCE
    if _INSTANCE is None:
        _INSTANCE = WindowsBackend() if IS_WINDOWS else LinuxBackend()
        logging.info(f"Platform backend: {_INSTANCE.name} (DESKTOP_ENV={DESKTOP_ENV})")
    return _INSTANCE


if __name__ == '__main__':
    import time
    logging.basicConfig(level=logging.INFO, format='%(message)s')
    p = get_platform()

    if '--test-keylock' in sys.argv:
        # ⚠ KLAVYE KİLİDİ TESTİ — GÜVENLİ: 15sn sonra OTOMATİK bırakır + panik + Ctrl+Alt+Del.
        if p.name != 'windows':
            print("Bu test yalnız Windows'ta çalışır."); sys.exit(0)
        LOCK_SEC = 15
        print("\n=== KLAVYE KİLİDİ TESTİ (GÜVENLİ) ===")
        print(f" Kilit {LOCK_SEC} saniye AKTİF olacak. Denemek için:")
        print("   • Alt+Tab, Win tuşu, Alt+F4  -> ENGELLİ olmalı")
        print("   • PANİK çıkış: Ctrl+Alt+Shift+Q  -> anında bırakır")
        print(f"   • {LOCK_SEC}sn sonra OTOMATİK bırakılır (kalıcı kilit YOK)")
        print("   • Ctrl+Alt+Del HER ZAMAN çalışır (nihai kaçış)\n")
        # Bağımsız SERT güvenlik: döngü takılsa bile 20sn'de zorla bırak.
        hard = threading.Timer(LOCK_SEC + 5, p.restore_shortcuts); hard.daemon = True; hard.start()
        p.disable_shortcuts(auto_release_sec=LOCK_SEC)
        for i in range(LOCK_SEC, 0, -1):
            print(f"  kilit... {i}   ", end='\r', flush=True); time.sleep(1)
        p.restore_shortcuts(); hard.cancel()
        time.sleep(0.5)
        print("\n\nBırakıldı. Şimdi Alt+Tab / Win tuşu ÇALIŞMALI. Test bitti.\n")
        sys.exit(0)

    # Varsayılan: GÜVENLİ öz-test (klavye kilidi HARİÇ) — her primitifi dener + HEMEN geri alır.
    print(f"\n=== Platform öz-test: {p.name} ===\n")
    print("1) Uyku engeli açılıyor...")
    p.disable_sleep()
    print("2) Ses: kapat (2sn) -> aç...")
    p.mute(); time.sleep(2); p.unmute()
    print("3) Taskbar: gizle (3sn) -> göster...")
    p.hide_taskbar(); time.sleep(3); p.show_taskbar()
    print("\n(kill_foreground_apps ve klavye kilidi bu testte YOK.)")
    print("Klavye kilidini denemek için: python platform_layer.py --test-keylock")
    print("=== Bitti. ===\n")

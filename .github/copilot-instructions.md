# Fatih Projesi - Copilot Instructions

## Proje Özeti

Bu proje, okullardaki akıllı tahtaları uzaktan yönetmek için kullanılan bir sistemdir. İki ana bileşenden oluşur:

1. **Server (Python/FastAPI)**: Merkezi yönetim sunucusu
2. **Client (Python/PyQt5)**: Akıllı tahtalarda çalışan istemci uygulaması

### Ana Özellikler
- Ekran kilitleme/açma (schedule bazlı veya manuel)
- USB ile acil kilit açma (pass.txt dosyası ile)
- Uzaktan kapatma komutu (mobil uygulama ile)
- Zamanlama sistemi (ders saatlerine göre kilitleme)
- Log kayıtları
- Dinamik şifre sistemi (Mebrecep uyumlu)

---

## Son Durum (26 Ocak 2026)

### ✅ Çalışan Sistem
- **Program durumu**: Çalışıyor
- **USB bypass**: Aktif ve çalışıyor
- **Server iletişimi**: Başarılı
- **Display Manager**: GDM3 (LightDM değil!)
- **Python/Qt**: Python 3.7 + PyQt5 5.14.2
- **Pre-login kilitleme**: Aktif (fatih-kiosk kullanıcısı ile)

### Son Düzeltmeler (v2.14.0)
1. **Pre-login/Açılış sorunu**: GDM/LightDM auto-login ayarları düzeltildi
2. **Mobilden güç kesme**: Shutdown komutları için sudo izinleri eklendi
3. **İnternetsiz şifre açılışı**: Local time fallback eklendi, schedule parse hatalarında kilitleme yapılmıyor
4. **Sağ tık kapat/yeniden başlat**: Birden fazla komut yöntemi deneniyor
5. **Autostart kontrolü**: fatih-kiosk autostart dosyası da kontrol ediliyor

### Güncel Kurulum Scriptleri
- `fatih-manager.sh` - Ana menü (Seçenek 1 = Tam kurulum + pre-login)
- `install-unified.sh` - Birleştirilmiş kurulum scripti (sudo izinleri dahil)
- `launch.sh` - Multi-display destekli başlatıcı (v5.0)

---

## Uzak Bilgisayar (Test Bilgisayarı) Bilgileri

| Bilgi | Değer |
|-------|-------|
| **Hostname** | etap |
| **OS** | Pardus 19 (Debian 10 Buster tabanlı) |
| **Display Manager** | GDM3 |
| **Qt Versiyonu** | 5.11 |
| **Kullanıcı** | etapadmin |
| **Sudo Şifresi** | `etap+pardus!` |
| **Tailscale IP** | 100.119.158.18 |
| **Proje Dizini** | `/home/etapadmin/Fatih_Projesi` |
| **Kurulu Uygulama** | `/opt/fatih-client/` |
| **Python venv** | `/opt/fatih-client/venv` |

### X11 Display Bilgisi
- **ogrenci** kullanıcısı: DISPLAY=:0
- **etapadmin** kullanıcısı: DISPLAY=:1
- **XAUTHORITY**: `/run/user/$(id -u)/gdm/Xauthority`

### SSH Bağlantısı (Tailscale Üzerinden)

**NOT:** Copilot bu SSH bağlantısını kullanarak uzak bilgisayarda test yapabilir. `ssh etap` komutu ile bağlanıp güncellemeleri test edebilir.

```bash
# Direkt bağlantı
ssh etap

# Veya
ssh etapadmin@100.119.158.18

# Sudo komutları için şifre:
echo 'etap+pardus!' | sudo -S <komut>
```

**~/.ssh/config ayarı:**
```
Host etap
    HostName 100.119.158.18
    User etapadmin
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### Hızlı Güncelleme ve Test Komutları

```bash
# 1. Yerel makinede commit ve push
git add -A && git commit -m "Değişiklik açıklaması" && git push origin main

# 2. Uzak bilgisayarda güncelleme (tek komutta)
ssh etap "cd ~/Fatih_Projesi && git pull origin main"

# 3. Dosyayı kopyala ve servisi yeniden başlat
ssh etap "echo 'etap+pardus!' | sudo -S cp ~/Fatih_Projesi/fatih_projesi_python/client/client.py /opt/fatih-client/"
ssh etap "echo 'etap+pardus!' | sudo -S pkill -f client.py"

# 4. Programı başlat (interaktif SSH ile)
ssh -t etap
cd /opt/fatih-client && ./launch.sh &

# 5. Log kontrolü
ssh etap "cat ~/fatih_client.log | tail -30"

# 6. TAM YENİDEN KURULUM (sorunlar devam ederse)
ssh -t etap
cd ~/Fatih_Projesi && git pull origin main
echo 'etap+pardus!' | sudo -S ./fatih-manager.sh
# Menüden 1) Kur seçin
```

---

## Proje Yapısı

```
Fatih_Projesi/
├── fatih_projesi_python/          # Python versiyonu (AKTİF KULLANILAN)
│   ├── client/                    # İstemci uygulaması
│   │   ├── client.py              # Ana istemci kodu
│   │   ├── config.ini             # Yapılandırma dosyası
│   │   ├── install-unified.sh     # Birleştirilmiş kurulum (app + pre-login)
│   │   ├── install.sh             # Eski kurulum scripti
│   │   ├── uninstall.sh           # Kaldırma scripti
│   │   ├── stop.sh                # Acil durdurma scripti
│   │   ├── launch.sh              # Başlatıcı script (v5.0 multi-display)
│   │   └── requirements.txt       # Python bağımlılıkları (PyQt5==5.14.2)
│   └── server/                    # FastAPI sunucu
│       └── app/
│           └── main.py            # Ana sunucu kodu
├── fatih-manager.sh               # Ana kurulum/yönetim menüsü
├── Fatih_Projesi/                 # C# Windows versiyonu (eski)
├── ConfigServices/                # C# Windows servisi
├── Kurulum/                       # C# Windows kurulum
└── Updater1/                      # C# Windows güncelleyici
```

---

## Deployment Workflow

### Geliştirme Ortamı
- **Geliştirici Bilgisayar**: Yerel makinede kod düzenlenir
- **Repository**: `cappittall/Fatih_Projesi` (GitHub)
- **Branch**: `main`

### Uzak Bilgisayara Güncelleme Adımları

1. **Yerel makinede değişiklikleri commit et ve push et:**
   ```bash
   cd /home/cappittall/Documents/Fatih_Projesi
   git add .
   git commit -m "Değişiklik açıklaması"
   git push origin main
   ```

2. **Uzak bilgisayarda güncelle (SSH veya Alpemix ile):**
   ```bash
   cd ~/Fatih_Projesi
   git pull origin main
   
   # Değişen dosyaları kopyala:
   sudo cp fatih_projesi_python/client/client.py /opt/fatih-client/
   sudo cp fatih_projesi_python/client/launch.sh /opt/fatih-client/
   ```

3. **Servisi yeniden başlat:**
   ```bash
   # Çalışan process'i durdur
   pkill -f client.py
   
   # Yeniden başlat
   cd /opt/fatih-client && ./launch.sh &
   ```

---

## Client Kurulum/Kaldırma

### Kurulum (Tek Komut)
```bash
cd ~/Fatih_Projesi
sudo ./fatih-manager.sh
# Seçenek 1: Tam kurulum (app + pre-login)
```

Bu kurulum şunları yapar:
- Fatih Client uygulamasını kurar
- PyQt5 5.14.2 kurar (Pardus 19 Qt 5.11 uyumlu)
- `fatih-kiosk` kullanıcısı oluşturur
- Display Manager (LightDM/GDM) auto-login yapılandırır
- Bilgisayar açıldığında login ÖNCESİ kilit ekranı gösterir

### Manuel Başlatma (Test için)
```bash
# etapadmin olarak çalıştırmak için:
export DISPLAY=:1
export XAUTHORITY=/run/user/$(id -u)/gdm/Xauthority
cd /opt/fatih-client
./venv/bin/python client.py &
```

### Acil Durdurma (Ekran kilitlenme döngüsü olduğunda)
```bash
cd ~/Fatih_Projesi/fatih_projesi_python/client
sudo ./stop.sh
```

### Tam Kaldırma
```bash
cd ~/Fatih_Projesi/fatih_projesi_python/client
sudo ./uninstall.sh
```

---

## Nasıl Çalışır (Pre-Login Flow)

1. **Bilgisayar açılır** → `fatih-kiosk` kullanıcısı otomatik login olur
2. **Fatih kilit ekranı gösterilir** (kiosk modunda)
3. **USB veya şifre ile kilit açılır**
4. **Display Manager restart olur** → Normal login ekranı gösterilir
5. **Öğretmen/Admin** kendi kullanıcısıyla login olur

---

## Önemli Dosya Konumları (Kurulum Sonrası)

| Dosya | Konum |
|-------|-------|
| Ana uygulama | `/opt/fatih-client/` |
| Python venv | `/opt/fatih-client/venv` |
| Kiosk launcher | `/opt/fatih-client/kiosk-launcher.sh` |
| Launch script | `/opt/fatih-client/launch.sh` |
| Kiosk autostart | `/home/fatih-kiosk/.config/autostart/` |
| Log dosyası | `/opt/fatih-client/logs/kiosk.log` |
| Error log | `/opt/fatih-client/logs/kiosk.err.log` |
| GDM config | `/etc/gdm3/custom.conf` veya `/etc/gdm/custom.conf` |
| LightDM config | `/etc/lightdm/lightdm.conf` |
| Config backup | `*.backup-fatih` |

---

## USB Kilit Açma Sistemi

USB bellek ile ekran kilidi açılabilir. USB'de şu dosyalar olmalı:

1. **pass.txt** - Normal kilit açma
   - İçerik: `32541kehİUFali_veli_hüseyin?İ44EHEJSTRİHTEMES5488965E8GİEİ`

2. **rmove.txt** - Sistemi kaldırma komutu
   - İçerik: `uege32541kehİUFali_veli_hüseyin?İEHEJSTRİH52874TEMES548965E8GİEİ`

**Önemli:** USB takılıyken server veya schedule kilitleme komutu gönderirse, sistem kilitlemeyi atlar. USB çıkarılınca kilitlenir.

---

## Bilinen Sorunlar ve Çözümler

### 1. Pre-login / Açılışta Devreye Girmeme
**Sorun:** Program kullanıcı login ekranından önce devreye girmiyor.

**Çözüm (26 Ocak 2026):**
- GDM/LightDM için `fatih-kiosk` kullanıcısı auto-login ayarları yapıldı
- `/home/fatih-kiosk/.config/autostart/fatih-kiosk.desktop` dosyası kontrol ediliyor
- Display Manager config dosyaları: `/etc/gdm3/custom.conf` veya `/etc/lightdm/lightdm.conf`

### 2. Mobilden Güç Kesme / Sağ Tık Kapat-Yeniden Başlat
**Sorun:** Shutdown/reboot komutları çalışmıyor.

**Çözüm (26 Ocak 2026):**
- `/etc/sudoers.d/fatih-client` dosyasına shutdown/reboot izinleri eklendi
- Birden fazla komut yöntemi deneniyor (sudo poweroff, systemctl poweroff, vb.)

### 3. İnternetsiz Şifre Açılışında Geri Kilitleme
**Sorun:** İnternet yokken şifre ile açılınca tekrar kilitleniyor.

**Çözüm (26 Ocak 2026):**
- Dinamik şifre kontrolünde local time fallback eklendi
- Schedule parse hatalarında kilitleme YAPILMIYOR (return)
- Manual override şifre ile açılışta da aktif

### 4. Ekran Kilitleme Döngüsü
**Sorun:** USB ile ekran açıldıktan birkaç saniye sonra tekrar kilitlenip açılıyor.

**Çözüm:**
- `check_schedule()`: Kilitleme öncesi `check_usb_password()` kontrolü
- `process_commands()`: Server komutu geldiğinde USB kontrolü

### 5. Autostart Kontrolü
**Sorun:** Kurulumdan sonra Autostart: ✗ Yok gösteriyor.

**Çözüm (26 Ocak 2026):**
- `fatih-manager.sh`'te hem `fatih-kiosk.desktop` hem de `fatih-client-autostart.desktop` kontrol ediliyor
- GDM/LightDM auto-login durumu da kontrol ediliyor

### 6. X11 Authentication Hatası
**Sorun:** "MIT-MAGIC-COOKIE-1" hatası veya "could not connect to display"

**Çözüm:**
- GDM3 sistemlerinde XAUTHORITY: `/run/user/$(id -u)/gdm/Xauthority`
- `launch.sh` v5.0 multi-display desteği ile otomatik algılıyor

### 7. Qt/PyQt5 Uyumluluk Sorunları (Pardus 19)
**Sorun:** Qt 5.11 ile PyQt5 uyumsuzlukları

**Çözüm:**
- PyQt5==5.14.2 ve PyQt5-sip==12.8.1 kullanılıyor
- `unset QT_PLUGIN_PATH` ile sistem Qt'si kullanılıyor

---

## Geliştirme Notları

### Timer'lar (client.py)
- **USB Check Timer**: 3 saniye (usb_check_interval)
- **Schedule Timer**: 60 saniye
- **Server Polling Timer**: Ayarlanabilir (polling_interval)
- **Maintenance Timer**: 25 saniye

### Önemli Flag'ler
- `is_locked`: Ekran kilitli mi?
- `manual_override`: Manuel/USB ile açıldı mı? (Schedule'ı bypass eder)
- `unlocked_by_usb`: USB ile mi açıldı? (USB çıkarılınca kilitleme için)

---

## İletişim

- **Repository**: https://github.com/cappittall/Fatih_Projesi
- **Branch**: main



## Essential Commands

```bash
# Task complete sound (mandatory)
canberra-gtk-play --id=complete
```


## Who Am I?

I am freelance developer, name is Hakan Çetin - netcat16@gmail.com, working on this project. My nick name is Cappittall at all platforms.
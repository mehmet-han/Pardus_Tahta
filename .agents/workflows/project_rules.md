---
description: Proje Değişiklik Kuralları (Fatih Client - AI Knowledge)
---

# Fatih Client - Proje Mimarisi ve AI Geliştirme Kuralları (MANDATORY RULES)

Eğer mevcut veya gelecekteki bir AI ajanı (sistem asistanı) bu projede (Pardus_Tahta) bir kod değişikliği, hata ayıklama (debug) veya yeni özellik ekleme işlemi yapacaksa, aşagıdaki **kırmızı çizgileri (strict rules)** HARFİYEN OYNAMADAN kabul edip uygulamak zorundadır.

---

## 🔒 1. GÜVENLİK VE ŞİFRELEME (OBFUSCATION) BÖLÜMÜ
Sistem okullara açık kaynak olarak dağıtıldığı için öğrencilerin ve yetkisiz kişilerin şifreleri çalmaması adına çok katmanlı bir şifreleme bulunmaktadır.
- **Asla Plaintext Yok:** `client.py` ve `setup.sh` dosyalarının içerisine hiçbir sunucu API URL'i, `wb_user`, `wb_pass`, admin şifresi veya USB hash değeri DÜZ METİN (Plaintext) olarak yazılamaz.
- **Zero-Footprint XOR ve RAM Temizliği:** Hassas bilgiler (URL, kullanıcı adı, API parolası vb.) kesinlikle `config.ini` veya diğer dosyalara YAZILAMAZ. Bu veriler `client.py` içerisine XOR hex string kodlaması olarak gömülür ve yalnızca ağ istekleri yapılırken (`requests.post` milisaniyesinde) çözülür. İstek biter bitmez Python'ın yerel RAM hafızasından `del _url, _pwd` vb. ile HIZLICA SİLİNMEK ZORUNDADIR.
- **MITM Koruması:** Ağ bağlantılarında asla `verify=False` kullanılmaz. Sertifika doğrulaması (`verify=True`) her zaman şarttır.
- **Config Güvenliği:** Oluşturulan `config.ini` dosyaları `chmod 600` Linux yetkilerini barındırmalıdır. `setup.sh` içinde hassas işlemler (örrn: şifre okumaları vs) komut satırı ve Bash komut geçmişine (history) iz bırakmamalıdır.
- **Cython Compiled (.so):** Kurulum scriptleri (`setup.sh`, `install-unified.sh`) her zaman `client.py` dosyasını `Cython` paketleyicisi ile C-uzantısına (`client.so` veya `client.c`) derler. Okunabilir haldeki `client.py` dosyası kurulum hedefine atıldıktan sonra SİLİNMEK ZORUNDADIR. Python kodlarının çıplak kalması kesin yasaktır. Sistem, dışarıya şifrelenmiş `.so` modülünü güvenli bir biçimde import edebilmek adına sadece sığ bir `fatih.py` taşıyıcısı ile tetiklenir ve arkaplan kabukları (`launch.sh`, `fatih-manager.sh` vs.) direkt olarak bu dosyayı muhatap alır.
- **Varsayılan Kurulum Şifresi & Eski Sistemlere Destek (Migration):** Sistemin varsayılan admin şifresi KESİNLİKLE `803580` olmalıdır (`mebre` vb. geçmiş isimler default olarak atanamaz). Ancak eski versiyondan kalma tahtalardaki yapılandırma (`config.ini`) uyumsuzluklarını önlemek adına `client.py` içerisindeki varsayılan şifre kural kontrollerinde `803580` ile beraber `mebre` ihtimali de KONTROL EDİLMELİDİR. Yeni kurulum (`setup.sh`) her zaman default şifreyi `803580` yazar.
---

## 🖥 2. ARAYÜZ (UI), ODAK YÖNETİMİ VE PENCERE MİMARİSİ
Pardus (Cinnamon/XFCE vb.) ortamlarında, kilit ekranı arka plana atılıp masaüstüne (student user) kaçış yapılması engellenmiştir. Arayüzün geliştirilmesinde hayati kurallar vardır:
- **Asla QDialog.exec_() Yok:** Sistem LockScreen (kaldırılamaz, AlwaysOnTop, Frameless) yapısına dayalıdır. `QDialog.exec_()` kullanıldığında Cinnamon/X11 pencerelerin input/focus (odak) ayarlarını bozar ve kilit ekranı kaybolabilir (Segmentation fault/UI freezing tetiklenir).
- **Qt.Tool Bayrağı (Flag):** Uyarı, Parola veya Yapılandırma ekranları (dialogs) daima Model/Tool `QtCore.Qt.Tool | QtCore.Qt.FramelessWindowHint | QtCore.Qt.WindowStaysOnTopHint` ile ana kilit ekranının (parent) üzerine render edilmelidir.
- **Embedded Numpad:** Virtual OSK (On-Screen Keyboard) sistemin çökmesine neden olduğu için sanal klavyeler kaldırılmış olup, kullanıcıdan veri alma (şifre vb.) işlemleri tamamen formun kendisine gömülmüş (Embedded) Custom Numpad mekanizması ile gerçekleştirilmelidir.
- **Odak (Focus) ve Numpad Hedeflemesi (Targeting):** Şifre değiştirme gibi çoklu input ekranlarında, Embedded Numpad'in doğru alana (`set_target`) odaklanması çok katı bir şekilde ayarlanmalıdır. Ayrıca `KeyboardLineEdit`'e fareyle tıklandığında `eventFilter` ile Numpad odağının otomatik güncellenmesine dikkat edilmelidir. "Mevcut şifre" alanında varsayılan şifre gösteriliyorsa Numpad otomatik olarak "Yeni Şifre" kutusuna hedeflenmelidir.
- **Yanlış Maskeleme (EchoMode) Kuralı:** Arayüz güvenli olsa da, "Kurum Kodu" veya tahta isimleri ASLA `QLineEdit.EchoMode.Password` ile maskelenmemelidir. Şifre alanı dışındaki config değerleri görünür olmalıdır.

---

## 📦 3. PAKETLEME VE GITHUB YÖNETİMİ
Oluşturulan kodlar doğrudan son kullanıcı (öğretmenler) tarafından kullanılacağı için dağıtım ve paketleme süreci el ile YAPILAMAZ.
- **C# İzolasyonu:** Bu dizin yalnızca Python projesini tutar. C# tabanlı `Fatih_Projesi`, `ClassVariables.cs` içeren referans klasörleri başka bir depoda (`Fatih_Client_CSharp`) güvenceye alınmıştır. Bu depoda asla bulunmamalıdır.
- **paket_olustur.py:** Deployment (Dağıtım) dosyası olan ZIP arşivleri sadece ve sadece kök dizindeki `paket_olustur.py` komutu `python paket_olustur.py` çalıştırılarak inşa edilmelidir. Bu paketleyici, `git` temizliğini, versiyon damgasını ve greping tabanlı sızıntı kontrolünü AI yerine otomatik yapar.
- **push_to_github.md:** GitHub push işlemlerinden önce her zaman versiyon increment aracı çalıştırılmalıdır (Lütfen `.agents/workflows/push_to_github.md` komutunu okuyun).

---

## 📂 4. KURULUM MİMARİSİ
- **Tek Tuş Bash / Curl:** Öğretmen kurulumları `install_from_github.sh` uzaktan erişim URL'si ile çalışır, eğer bu dosyanın işleyiş tarzı bozulursa binlerce tahta öksüz kalabilir. Cihaz kurulum esnasında `setup.sh` ve `install-unified.sh` çalıştırır; bu betikler şifreli (.so) sistemi `/opt/fatih-client` altına gömer, `.desktop` ile sistem Autostart'a kayıt eder.
- **Kaldırma (Uninstall.sh):** Programın izinsiz kaldırılmasını önlemek maksadıyla `sudo fatih-uninstall` içerisinde gizlenmiş olan SHA-256 doğrulayıcı kod (sır tutulur: 803435... uzantısı), kaldırma onayı sunar. Systemd temizliği ve service pkill (katletme) evreleri bozulmamalıdır.

---

## 🔑 5. ADMIN ŞİFRE SİSTEMİ — DOKUNULMAZ REFERANS (PASSWORD INVARIANT CONTRACT)

> ⛔ **BU BÖLÜM MUTLAK DOKUNULMAZDIR.** Herhangi bir AI ajanı şifre, parola, `admin_password`, `ChangePasswordWidget`, `BoardConfigWidget`, `validate_admin_password`, Numpad hedefleme veya login/unlock mantığına dokunacaksa bu bölümü önce **tamamen okumalı** ve aşağıdaki kuralları harfiyen uygulamalıdır. Aksi halde yapılan değişiklik **REDDEDILIR**.

### 5.1 Varsayılan Şifre Değeri
- Sistemin varsayılan admin şifresi daima **`803580`** olmalıdır.
- **Eski değer `mebre`** bazı tahtalarda hâlâ config.ini'de bulunabilir. Kod içinde `mebre` → `803580` dönüşümü yapılmalıdır ama `mebre` asla default olarak ATANAMAZ.

### 5.2 Dosya Bazında Şifre Konumları (Dokunma Haritası)

| Dosya | Konum/Değişken | Doğru Değer | Not |
|---|---|---|---|
| `config.ini` | `admin_password` | `803580` | Yeni kurulum default'u |
| `setup.sh` | `ADMIN_PASSWORD` (satır ~97) | `"803580"` | Bash değişkeni, yeni kurulumda yazılır |
| `client.py` — `ChangePasswordWidget.init_ui()` | `SETTINGS.get('admin_password', '803580')` | fallback `803580` | Mevcut şifre gösterimi |
| `client.py` — `ChangePasswordWidget.init_ui()` | `self.current_field.setText('803580')` | Sabit `803580` | Default ise readonly gösterilir |
| `client.py` — `ChangePasswordWidget.change_password()` | `SETTINGS.get('admin_password', '803580')` | fallback `803580` | Doğrulama |
| `client.py` — `BoardConfigWidget.fetch_boards()` | `SETTINGS.get('admin_password', '803580')` | fallback `803580` | Tahta getirme şifre kontrolü |
| `client.py` — `validate_admin_password()` | `SETTINGS.get('admin_password', '803580')` | fallback `803580` | Login doğrulama |
| `client.py` — `kiosk_show_board_config()` | `SETTINGS.get('admin_password', '803580')` | fallback `803580` | Yapılandırma erişim kontrolü |
| `client.py` — `__main__` test bloğu | `SETTINGS.get('admin_password', '803580')` | fallback `803580` | Debug çıktısı |

### 5.3 `ChangePasswordWidget` — Mevcut Şifre Alanı Kuralları
```
Eğer config'deki admin_password == '803580' VEYA == 'mebre':
  → self._is_default_password = True
  → current_field.setEchoMode(Normal)     # Şifre GÖRÜNSİN
  → current_field.setText('803580')        # SABİT DEĞER
  → current_field.setReadOnly(True)        # Kullanıcı DEĞİŞTİREMESİN
  → Numpad hedefi → new_field              # Direkt yeni şifre alanına

Aksi halde (kullanıcı şifreyi daha önce değiştirmişse):
  → self._is_default_password = False
  → current_field.setEchoMode(Password)   # Şifre GİZLİ
  → current_field.setText('')              # BOŞ, kullanıcı girsin
  → Numpad hedefi → current_field          # Mevcut şifreye
```

### 5.4 Numpad Hedefleme (Focus Targeting) — Bozulmaması Gereken Mantık
- **ChangePasswordWidget:** 3 input alanı var (`current_field`, `new_field`, `confirm_field`). `_connect_focus_tracking()` + `eventFilter()` ile her alana tıklandığında `self.numpad.set_target(obj)` çağrılır. Varsayılan şifre durumunda initial hedef `new_field`.
- **BoardConfigWidget:** 2 input alanı var (`corporate_code_field`, `password_field`). Aynı `_connect_focus_tracking()` + `eventFilter()` mekanizması. Initial hedef `password_field`.
- **LoginDialog:** 1 input alanı var (`password_field`). Numpad doğrudan bu alana yazıyor.
- **KURAL:** `eventFilter` metodunda `event.type() == event.Type.FocusIn` kontrolü **ASLA KALDIRILMAMALI**. Bu mekanizma, kullanıcı fareyle farklı bir input'a tıkladığında Numpad'in otomatik olarak o alana geçmesini sağlar.

### 5.5 `mebre` → `803580` Migration Kontrolü
Aşağıdaki her yerde `if config_password == 'mebre': config_password = '803580'` satırı bulunmalı:
1. `ChangePasswordWidget.init_ui()` — mevcut şifre gösterimi
2. `ChangePasswordWidget.change_password()` — şifre doğrulama
3. `BoardConfigWidget.fetch_boards()` — tahta listesi şifre kontrolü
4. `validate_admin_password()` — login doğrulama
5. `kiosk_show_board_config()` — `_pw == 'mebre'` kontrolü

### 5.6 ASLA YAPILMAMASI GEREKENLER
- ❌ `admin_password` fallback değerini `'803580'` dışında bir şeye değiştirmek
- ❌ `current_field.setText('803580')` satırını değiştirmek veya silmek
- ❌ `mebre` migration kontrollerini kaldırmak
- ❌ Varsayılan şifre durumunda `current_field`'ı `readOnly(False)` yapmak
- ❌ `eventFilter` focus tracking mantığını kaldırmak veya değiştirmek
- ❌ Numpad `set_target()` çağrılarının sırasını değiştirmek
- ❌ BoardConfigWidget'teki `corporate_code_field`'a `EchoMode.Password` eklemek

---

> Eğer kullanıcı (USER) *"Projeye uzun zaman sonra geri döndük, şu bug var"* vs. derse, LÜTFEN ASLA yukarıdaki kuralların (Focus-ZOrder, Obfuscation, C# İzole vb.) Dışına ÇIKACAK şekilde 'çevik ama riskli' (fragile) kod değişiklikleri YAPMA!

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
- **Cython Compiled (.so):** Kurulum scriptleri (`setup.sh`, `install-unified.sh`) her zaman `client.py` dosyasını `Cython` paketleyicisi ile C-uzantısına (`client.so` veya `client.c`) derler. Okunabilir haldeki `client.py` dosyası kurulum hedefine atıldıktan sonra SİLİNMEK ZORUNDADIR. Python kodlarının çıplak kalması kesin yasaktır.

---

## 🖥 2. ARAYÜZ (UI), ODAK YÖNETİMİ VE PENCERE MİMARİSİ
Pardus (Cinnamon/XFCE vb.) ortamlarında, kilit ekranı arka plana atılıp masaüstüne (student user) kaçış yapılması engellenmiştir. Arayüzün geliştirilmesinde hayati kurallar vardır:
- **Asla QDialog.exec_() Yok:** Sistem LockScreen (kaldırılamaz, AlwaysOnTop, Frameless) yapısına dayalıdır. `QDialog.exec_()` kullanıldığında Cinnamon/X11 pencerelerin input/focus (odak) ayarlarını bozar ve kilit ekranı kaybolabilir (Segmentation fault/UI freezing tetiklenir).
- **Qt.Tool Bayrağı (Flag):** Uyarı, Parola veya Yapılandırma ekranları (dialogs) daima Model/Tool `QtCore.Qt.Tool | QtCore.Qt.FramelessWindowHint | QtCore.Qt.WindowStaysOnTopHint` ile ana kilit ekranının (parent) üzerine render edilmelidir.
- **Embedded Numpad:** Virtual OSK (On-Screen Keyboard) sistemin çökmesine neden olduğu için sanal klavyeler kaldırılmış olup, kullanıcıdan veri alma (şifre vb.) işlemleri tamamen formun kendisine gömülmüş (Embedded) Custom Numpad mekanizması ile gerçekleştirilmelidir.

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

> Eğer kullanıcı (USER) *"Projeye uzun zaman sonra geri döndük, şu bug var"* vs. derse, LÜTFEN ASLA yukarıdaki kuralların (Focus-ZOrder, Obfuscation, C# İzole vb.) Dışına ÇIKACAK şekilde 'çevik ama riskli' (fragile) kod değişiklikleri YAPMA!

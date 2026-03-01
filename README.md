Elbette, projeniz için tüm detayları içeren, kurulum ve kullanım adımlarını açıklayan kapsamlı bir `README.md` dosyasını aşağıda Türkçe olarak hazırladım. Bu dosyayı projenizin ana klasörüne `README.md` olarak kaydedebilirsiniz.

---

# Fatih Client Projesi

Bu proje, akıllı tahtaları (Pardus, Ubuntu vb. Debian tabanlı sistemler) merkezi bir sunucu üzerinden yönetmek, kilitlemek ve kontrol etmek için geliştirilmiş bir istemci yazılımıdır.

## Proje Hakkında

Fatih Client, akıllı tahtaların yetkisiz kullanımını engellemek amacıyla tasarlanmıştır. Sistem açıldığında otomatik olarak başlar, ekranı kilitler ve klavye/fare girişlerini devre dışı bırakır. Tahtanın kilidi, merkezi yönetim panelinden veya yetkili bir USB bellek kullanılarak açılabilir.

## Özellikler

-   **Merkezi Yönetim:** Tahtaları web tabanlı bir panelden kilitleme ve kilit açma.
-   **Anlık Mesajlaşma:** Yönetim panelinden tahtanın ekranına anlık mesaj gönderme.
-   **USB Anahtar Desteği:** Özel olarak hazırlanmış bir USB bellek ile tahtanın kilidini açma.
-   **Otomatik Kilitleme:** Kilidi açmak için kullanılan USB bellek çıkarıldığında tahtayı otomatik olarak yeniden kilitleme.
-   **Uzaktan Kapatma:** Yönetim panelinden tahtayı uzaktan kapatma komutu gönderme.
-   **Uzaktan Kaldırma:** Yönetim panelinden istemci yazılımını uzaktan kaldırma.
-   **Gözetmen (Watchdog) Servisi:** İstemci yazılımı herhangi bir nedenle kapanırsa, 10 saniye içinde otomatik olarak yeniden başlatır.

---

## Kilit Açma ve Kilitleme Yöntemleri

Tahtanın kilidini yönetmek için üç ana yöntem bulunmaktadır:

### 1. Sunucu Üzerinden Kontrol (Önerilen Yöntem)
En temel ve esnek yöntem, yönetim paneli üzerinden tahtanın durumunu (`kilitli` veya `açık`) değiştirmektir.
-   **Kilitlemek için:** Yönetim panelinden ilgili tahtayı seçip "Kilitle" komutunu gönderin.
-   **Açmak için:** Yönetim panelinden ilgili tahtayı seçip "Kilidi Aç" komutunu gönderin.

### 2. USB Anahtar ile Kilit Açma
Fiziksel olarak tahtanın başında olduğunuzda, özel olarak hazırlanmış bir USB bellek ile kilidi açabilirsiniz.

**USB Anahtar Nasıl Hazırlanır?**
1.  Herhangi bir USB belleği bilgisayarınıza takın (içindeki veriler silinmeyecektir).
2.  USB belleğin ana dizininde `pass.txt` adında bir metin dosyası oluşturun.
3.  Oluşturduğunuz `pass.txt` dosyasının içine aşağıdaki şifreyi **hiçbir boşluk olmadan** kopyalayıp yapıştırın ve kaydedin:
    ```
    32541kehİUFali_veli_hüseyin?İ44EHEJSTRİHTEMES5488965E8GİEİ
    ```
4.  USB belleğiniz artık bir "kilit açma anahtarı" olarak hazırdır. Bu USB'yi kilitli olan tahtaya taktığınızda, tahtanın kilidi birkaç saniye içinde otomatik olarak açılacaktır.

### 3. USB Anahtar Çıkarıldığında Otomatik Kilitleme
Eğer bir tahtanın kilidi USB anahtar kullanılarak açıldıysa, bu USB anahtar tahtadan çıkarıldığında istemci bunu algılar ve sistemi **otomatik olarak yeniden kilitler**. Bu özellik, tahtanın kilidinin açık unutulmasını engeller.

---

## Kurulum

Kurulum işlemi `root` yetkileri gerektirir ve `install.sh` betiği ile otomatik olarak gerçekleştirilir.

### Sistem Gereksinimleri
-   Debian tabanlı bir Linux dağıtımı (Pardus, Ubuntu vb.)
-   Kurulum için `sudo` veya `root` yetkisi.
-   İnternet bağlantısı (bağımlılıkların indirilmesi için).

### Kurulum Adımları

1.  Proje dosyalarını sunucudan indirin veya bir USB bellek ile tahtaya kopyalayın.

2.  Terminali açın ve proje dosyalarının bulunduğu dizine gidin. Örneğin, dosyalar `Masaüstü/client` klasöründeyse:
    ```bash
    cd ~/Masaüstü/client
    ```

3.  `install.sh` betiğini çalıştırılabilir yapın:
    ```bash
    chmod +x install.sh
    ```

4.  Kurulumu `sudo` yetkisiyle başlatın:
    ```bash
    sudo ./install.sh
    ```
    Kurulum betiği gerekli tüm adımları (bağımlılıkları kurma, dosyaları kopyalama, otomatik başlatmayı ayarlama vb.) otomatik olarak yapacaktır.

5.  **Yeniden Başlatma (ZORUNLU):** Kurulum tamamlandıktan sonra, yapılan değişikliklerin (özellikle klavye/fare erişim izinlerinin) geçerli olması için tahtayı **mutlaka yeniden başlatmanız gerekmektedir.**

Kurulumdan sonra istemci yazılımı, kullanıcı oturum açtığında otomatik olarak başlayacaktır.

---

## Yapılandırma

İstemcinin ayarları `/etc/fatih-client/config.ini` dosyasında bulunur. Genellikle kurulumdan sonra bu dosyayı değiştirmeniz gerekmez, ancak her tahtanın sunucu tarafından tanınması için **özellikle** aşağıdaki iki ayarın doğru yapıldığından emin olun:

```ini
[settings]
# ... diğer ayarlar ...

# Her bir tahtanın ait olduğu kurum kodu
corporate_code = 1001

# Sunucudaki tahta ID'si. HER TAHTA İÇİN FARKLI OLMALIDIR!
board_id = 1

# ... diğer ayarlar ...
```
-   `corporate_code`: Kurumunuzu tanımlayan koddur.
-   `board_id`: Yönetim panelindeki her bir tahtayı temsil eden **benzersiz** bir numaradır. Yeni bir tahtaya kurulum yaparken bu numarayı değiştirmeniz gerekir.

---

## Sorun Giderme (Log Dosyaları)

İstemci yazılımı, çalışmasıyla ilgili tüm adımları ve olası hataları log dosyalarına kaydeder. Bir sorun yaşanması durumunda bu dosyalar incelenmelidir.

Log dosyaları `/opt/fatih-client/logs/` dizininde bulunur:
-   `/opt/fatih-client/logs/watchdog.log`: `launch.sh` gözetmen betiğinin logları. İstemcinin başlatılıp başlatılmadığını gösterir.
-   `/opt/fatih-client/logs/client.out.log`: İstemcinin normal çalışma logları (sunucuya bağlanma, kilit açma/kapama bilgileri vb.).
-   `/opt/fatih-client/logs/client.err.log`: İstemcinin karşılaştığı hataların logları.

Bir log dosyasını incelemek için terminalde `cat` komutunu kullanabilirsiniz:
```bash
cat /opt/fatih-client/logs/client.err.log
```

---

## Yazılımı Kaldırma

İstemci yazılımını sistemden kaldırmak için aşağıdaki adımları izleyin.

### Yöntem 1: Uzaktan Kaldırma
Yönetim panelinden ilgili tahtaya "Sistemi Kaldır" komutu göndererek yazılımın kendisini otomatik olarak kaldırmasını sağlayabilirsiniz.

### Yöntem 2: Manuel Kaldırma
Tahtaya fiziksel erişiminiz varsa, aşağıdaki komutları terminalde çalıştırarak yazılımı ve ilgili tüm dosyaları manuel olarak silebilirsiniz:

```bash
sudo rm -f /etc/xdg/autostart/fatih-client-autostart.desktop
sudo rm -rf /opt/fatih-client
sudo rm -rf /etc/fatih-client
echo "Fatih Client başarıyla kaldırıldı."
```
Bu komutları çalıştırdıktan sonra sistemi yeniden başlattığınızda yazılım bir daha çalışmayacaktır.
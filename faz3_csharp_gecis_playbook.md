---
description: Faz 3 — C# (Windows) istemcisini v6 cihaz sözleşmesine taşıma tık-tık checklist'i
son_guncelleme: 2026-07-15
---

# Faz 3 — C# (Windows) İstemcisi v6 Geçiş Playbook'u

> **Amaç:** Pardus/Python (Faz 2) için yaptığımız her cihaz-tarafı değişikliğinin C#'taki **birebir
> karşılığını** çıkarmak, böylece Faz 3'e geldiğimizde method-method "tık tık" ilerleyip hiçbir şeyi
> atlamamak. Bu dosya, kod yazılırken **kontrol listesi** olarak açılır.
>
> **Altın kural (project_rules §5A Faz 3):** Faz 1'de tanımlanan **AYNI** cihaz sözleşmesi kullanılır.
> **Yeni endpoint tasarlanmaz.** C#, `apps/akilliTahtaCihaz`'ın zaten sunduğu uçlara konuşur.

Depo: `C:\Github\Fatih_Client_CSharp` — asıl/ana proje (Pardus ondan türetilmiştir).

---

## 0. Ön koşullar (Faz 3'e başlamadan)

- [ ] Faz 1 v5 modülü (`apps/akilliTahtaCihaz`) prod'da canlı ve doğrulanmış olmalı.
- [ ] Faz 2 (Pardus) sahada pilotta sorunsuz çalışıyor olmalı — sözleşme "oturmuş" sayılır.
- [ ] `apiv5.mebre.com.tr` geçerli TLS sertifikasına sahip olmalı (C# de sertifika doğrular; hatalı
      sertifika tüm istemciyi çalışamaz yapar — Pardus'taki `verify=True` muadili).

---

## 1. Sözleşme referansı (C#'ın konuşacağı v5 uçları)

Kaynak: `C:\Github\v5\src\apps\akilliTahtaCihaz\akilliTahtaCihaz.md`. Taban yol:
`https://apiv5.mebre.com.tr/client/akilli_tahta_cihaz`

| Yeni endpoint | Eski v4 fnc | C# metodu (bugünkü) | Gövde (JSON) | Yanıt (`result`) |
|---|---|---|---|---|
| `POST /enroll` | — | *(yeni — yok)* | `{corporateCode, boardId, boardName}` + `X-Enroll-Secret` | `{ token }` |
| `POST /poll` | 5567 | `CtrlPost()` | — (kimlik token'dan) | `{ openClose, message, shutdown, systemRemove, logIstek }` |
| `POST /ack` | 5566 | `SetValue(col,val)` | `{ column, value }` | `{ ok }` |
| `POST /schedule` | 5563 | `GetValues()` | — | `{ schedule }` |
| `POST /log` | 5571 | `LogSave()/save()` | `{ logName, vog }` | `{ ok }` |
| `POST /log_reset` | 5574 | `logRequest()` | — | `{ ok }` |
| `GET  /version` | 5570 | `vck()` | — | `{ version }` |

**Auth (her istekte, `enroll` hariç):**
- `Authorization: Bearer <device_token>`
- `X-Timestamp: <unix_seconds>`  (sunucu ±300 sn replay penceresiyle doğrular — iki yönlü)

---

## 2. C# kod envanteri (bugünkü hâl — file:line)

### `Fatih_Projesi/ClassVariable.cs`
- [ ] `ApiUrl` (satır ~22): `"https://api.mebre.com.tr/v4/s_brt.php"` — **TEK URL, düz metin.**
- [ ] `wbUser`, `wbPass`, `userAgent` — Basic auth ve UA sabitleri.
- [ ] `class Tools` içinde: `cFnc(string)` (satır ~89, UserCore üretici), `userKey()` (satır ~119, User-Key üretici).
- [ ] `OPS.k` (kurum kodu), `OPS.t` (tahta no), `OPS.tn` (tahta adı) — config **Registry**'den yüklenir
      (satır ~406-458). **Pardus config.ini kullanır; C# Registry kullanır — token saklama yeri burası olacak.**
- [ ] `Vercion`, `SubVersiyon` — sürüm sabitleri.

### `Fatih_Projesi/ClassClient.cs`  (ağ katmanı — asıl iş burada)
Hepsi ortak desen: `WebClient` + `wb.Credentials = NetworkCredential(wbUser, wbPass)` +
`User-Key = Tools.userKey()` + `UserCore = Tools.cFnc("<fnc>")` + `UploadValues(ApiUrl, "POST", data)`.

- [ ] `logRequest()`  (satır ~29)  → 5574
- [ ] `save()` / `LogSave(LogName, vn)`  (satır ~53 / ~81)  → 5571
- [ ] `CtrlPost()`  (satır ~100)  → 5567; yanıt **satır ~136** `Encoding.UTF8.GetString(response).Split(',')`
      → `donut[]` (0=openClose,1=message,2=shutdown,3=systemRemove,4=logIstek)
- [ ] `SetValue(colmn, value)`  (satır ~157)  → 5566
- [ ] `GetValues()`  (satır ~193)  → 5563; `hours[8,19,3]`'e parse ediliyor + `tg` flag
- [ ] `vck()`  (satır ~283)  → 5570

### Yanıtın tüketildiği yerler (parse değişince kontrol)
- [ ] `Form1.cs:466` `ClassClient.CtrlPost()` çağrısı; `TahtaLock/Message/shutDown/SystemRemove/LogSend`
      statikleri (ClassClient.cs:26-27) üzerinden UI'a yansıyor.
- [ ] `Form1.cs:103/105/605/630` `SetValue("open_close", ...)` — komut ACK yerleri.

---

## 3. Tık-tık değişiklik listesi (Faz 3'te yapılacaklar)

### 3.1 Ağ/kimlik altyapısı (bir kere)
- [ ] **Host + yol:** `ApiUrl` tek sabiti kaldır; her metoda kendi v5 yolunu ver
      (`.../akilli_tahta_cihaz/poll` vb.). Not: v5 **ayrı sunucu** (`apiv5`), sadece yol değil host da değişir.
- [ ] **Auth mekanizması:** `NetworkCredential(wbUser,wbPass)` + `User-Key`/`UserCore` header'larını **kaldır**.
      Yerine her isteğe: `Authorization: Bearer <token>` + `X-Timestamp: <unix>`.
- [ ] **`Tools.cFnc()` ve `Tools.userKey()` artık kullanılmaz** (v5'te `fnc`-in-UserCore ve format-kontrolü yok).
      Silme; ama çağrılarını kes. `cFnc`'nin gerçek işlevi olan zaman damgası → `X-Timestamp` olarak yeniden doğar.
- [ ] **WebClient → HttpClient** (öneri): JSON gönder/al, `application/json`. WebClient de kalabilir ama
      JSON için HttpClient daha temiz. Gövde artık `NameValueCollection` değil, JSON.
- [ ] **`data["fnc"]="3480"` YEM'ini at** — v5'te fnc yok.

### 3.2 Token yaşam döngüsü (yeni — Pardus'ta config.ini, C#'ta Registry)
- [ ] **Enrollment:** ilk kurulumda/token yoksa `POST /enroll` (+`X-Enroll-Secret`) ile token al.
      `corporateCode=OPS.k`, `boardId=OPS.t`, `boardName=OPS.tn`.
- [ ] **Saklama:** token'ı Registry'de **şifreli** sakla (öneri: `ProtectedData`/DPAPI, LocalMachine kapsamı).
      Pardus tarafındaki XOR mantığının C# muadili. **Düz metin token yazma.**
- [ ] **Kurulum (`Kurulum/FKurulum.cs`) akışı:** okul tanıtımı yapılırken enroll tetiklenmeli; token
      Registry'ye yazılmalı. (Default `353535/19381938/0` kodlu test tahtaları da enroll olabilmeli.)

### 3.3 Metod-metod (her biri ayrı commit yapılabilir)
- [ ] `CtrlPost()` → `POST /poll`; yanıtı `Split(',')` yerine **JSON deserialize** et
      (`result.openClose` vb.). `TahtaLock=openClose`, `Message`, `shutDown`, `SystemRemove`, `LogSend` eşle.
      **Fail-safe:** ağ/hata durumunda bugünkü kilitleme davranışı korunur (server zaten kayıt yoksa kilitli döner).
- [ ] `SetValue(col,val)` → `POST /ack` gövde `{column:col, value:val}`. **Kolon whitelist server'da**
      zorlanıyor (open_close/shutdown/system_Remove/log_istek/message) — C# sadece bu adları göndersin.
- [ ] `GetValues()` → `POST /schedule`; `result.schedule` JSON'unu `hours[8,19,3]`'e parse et.
- [ ] `LogSave()/save()` → `POST /log` gövde `{logName, vog}`. (`log = Vercion-SubVersiyon:lname` biçimi korunur.)
- [ ] `logRequest()` → `POST /log_reset`.
- [ ] `vck()` → `GET /version`; `result.version` ile karşılaştır (bugünkü `Nw.Length<6` mantığı korunur).

### 3.4 Sürüm & paketleme
- [ ] Sürüm şeması `V6.xx.xx`'e geçer (Pardus ile hizalı).
- [ ] C# paketleme kendi akışında (bu depoda C# kodu tutulmaz kuralı **Pardus** deposu içindir; C# kendi deposunda).

---

## 4. ATLAMA — kritik kurallar (bunlar unutulursa saha kırılır)

1. **Çevrimdışı şifre formülü TEK TARAFLI DEĞİŞTİRİLEMEZ (§5C).** `generate_dynamic_password` mantığı
   **mobil + Pardus + C#** arasında paylaşımlı. Faz 4'te yenilenecek; C#'ı tek başına değiştirme.
   Faz 3'te formüle **dokunma**, sadece backend'i taşı.
2. **v4 dokunulmaz (§2).** Faz 3 boyunca sahadaki eski C# tahtalar hâlâ v4/s_brt.php'ye vurur; v4 ayakta kalır.
   Geçiş **paralel**: yeni sürüm v5'e, eski sürüm v4'e. Kesme Faz 5'te.
3. **Düz metin host/sır yasağı.** Pardus tarafında XOR + RAM temizliği zorunlu (project_rules §1/§8).
   C# bugün `ApiUrl`'i **düz metin** tutuyor — Faz 3'te en azından token'ı DPAPI ile şifrele; host'u da
   obfuske etmek Pardus'la tutarlılık için değerlendir.
4. **Fail-safe kilit davranışı korunur.** Sunucu/ağ yokken tahta kilitli kalmalı (bugünkü davranış +
   server'ın "kayıt yok → kilitli" default'u aynı yönde).
5. **`X-Timestamp` cihaz saatine bağlı.** Tahtanın saati çok kayarsa replay penceresi (±300 sn) dışında
   kalır → istek reddedilir. C#'ta NTP/saat senkron mantığı (bugün varsa) korunmalı.
6. **Rate-limit `corporate_code:board_id` bazlı** (server tarafında hallediliyor); C# tek okul-tek IP
   sorununu düşünmez, ama token'ı her tahtaya **ayrı** olmalı (enroll her tahta için ayrı token üretir).

---

## 5. Doğrulama (Faz 3 bitince)

- [ ] Pilot bir Windows tahtada enroll → token Registry'de şifreli → poll/ack/schedule/log/version uçtan uca.
- [ ] Panelden (ynt5 / mobil) kilitle/aç komutu → tahtada ≤ (poll aralığı + cache TTL) sürede görünür.
- [ ] v4 Apache log'unda o tahtadan `/v4/s_brt.php` trafiği **kesilmiş** olmalı (v5'e geçti kanıtı).
- [ ] Çevrimdışı (internetsiz) açma hâlâ çalışıyor (şifre formülüne dokunulmadı).
- [ ] Eski sürümdeki tahtalar etkilenmedi (hâlâ v4'te, sorunsuz).

---

İlgili: `pardusv6_project_rules.md` (§4.2 cihaz fnc envanteri, §5.1 host'a bağlı noktalar, §5C şifre, §5A fazlar).
Faz 2 (Pardus) tamamlanınca buradaki "bugünkü hâl" satır numaraları C# tarafında güncellenmeli.

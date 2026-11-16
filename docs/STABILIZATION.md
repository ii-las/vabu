# Masaüstü sağlamlaştırma

Bu çalışma `codex/guvenilirlik-duzeltmeleri` dalındadır. macOS üzerinde paket indirilmedi veya kurulmadı; ISO, grafik Linux oturumu, gerçek güncelleme, kilit/uyku ya da disk geri yükleme çalıştırılmadı. Ana `tasarim` dalı değiştirilmedi.

## Düzeltilen kaynak davranışları

| Bulgu | Değişiklik | Yerel doğrulama |
|---|---|---|
| Kabuk ve Ayarlar birbirinin değişikliğini ezebiliyordu | Ortak `config-store`, belge başına flock ve son belge üzerine anahtar bazında birleştirme; atomik replace/fsync; özel dosya izinleri; sıralı QML kuyruğu; KDL üreticisi de aynı kilitleri tüm okuma/doğrulama/değiştirme boyunca tutar | 16 gerçek alt süreçle eşzamanlı yazma |
| Bozuk JSON sessizce boş ayarlara dönüşüyordu | Tür/sürüm doğrulaması; geçersiz asıl dosyaya yazmayı durdurma; son sağlam yedeği açık eylemle kurtarma; bozuk aslı ayrı saklama | Bozuk, null, liste, gelecek sürüm, sembolik bağlantı ve geçersiz değerler |
| Kurtarma eski pano iznini geri açabilirdi | Bozuk dosyadan okuma/kurtarmada pano ve uygulama otomatik başlatma kapalı tutulur | Kurtarma öncesi/sonrası izin denetimi |
| Pano tek kötü istemciyle kapanabiliyordu | Sınırlı istek boyutu, nesne doğrulaması, bağlantı başına zaman aşımı/hata sınırı; arayüzde sıralı kuyruk; en fazla üç gecikmeli yeniden başlatma | Hatalı türler, JSON, kodlama, büyük istek, yarım bağlantı, kopma ve sonraki sağlam istek |
| Masaüstü ID her zaman pencere ID değildi | Desktop ID ve app_id ayrı tutulur; StartupWMClass ve native ID kuralları; gerçek açık pencereden kimlik seçimi; paylaşılan org.quickshell için tam başlık | Farklı ID, regex kaçışları, metadata ve otomatik başlatmada desktop ID kullanımı |
| Yeni katmanlarda Escape eksikti | Ortak FocusScope; çocuklardan yükselen Escape; arama alanı odağını koruma | Fedora akışında iki yeni menüye tuş gönderme eklendi; burada çalıştırılmadı |
| Boşta isteğe bağlı hizmet hata gösteriliyordu | Çalışıyor, kullanımda değil, yapılandırılmamış, başarısız ve bilinmiyor ayrılır | Taklit systemctl durumları |
| Bazı uyku düğmeleri kilidi beklemiyordu | Tüm kabuk uyku eylemleri başarılı kilitleme yardımcısından sonra suspend ister | Kaynak/JS kontrolü; gerçek kilit/uyku ayrıca gerekir |
| Flatpak başarısızken güncelleme tamamlandı denebiliyordu | RPM, kullanıcı Flatpak ve sistem Flatpak sonuçları ayrı; hata/iptal kesindir; son durum özel dosyada; ham çıktı saklanmaz | Başarı, RPM hatası, kısmi Flatpak hatası, iptal, eski running kaydı |
| Yeniden başlatma sorgusunun hatası öneriyle karışabiliyordu | DNF5 JSON yanıtı ve çıkış kodu birlikte doğrulanır; uyumsuz/eksik yanıt bilinmiyor olur | Kod + JSON birleşimleri |
| QML testinde zaman aşımı/eksik kayıt başarı sayılabiliyordu | Derleyici tamamlama işareti ve gerekli günlükler zorunlu; binding/ReferenceError/TypeError başarısızlık sayılır | Boş/eksik/başarısız kayıtlar |

Ayar dosyalarının mevcut üst düzey JSON biçimi korunur; `_schemaVersion: 1` yazılır. Bilinmeyen anahtarlar silinmez. Bozuk dosyanın son sağlam yedeği yoksa dosya korunur; sistem varsayılan görünümü kullanır ve hata gösterir. Yazma işleminde symlink izlenmez. Aynı anahtara yapılan eşzamanlı değişiklikte son tamamlanan yazma geçerlidir.

## CI ve görsel doğrulama

RPM akışına `tests/stability.py` eklendi. Kurulu Quickshell ile bileşen derleme ve gerçek kabuk açılışı zorunlu kontrol olarak hazırlandı. Singleton dosyalar hata metnine bakılarak atlanmaz; doğrudan referans verilerek yüklenir. Derleme tamamlanmazsa veya gerekli günlük yoksa iş durur. Statik QML denetimindeki seçili tür/özellik hataları da artık uyarıyla geçilmez.

Fedora ekran akışında 960×640 mantıksal ekran, 800×600 Ayarlar, Türkçe/İngilizce, %100/%150 yazı, yüksek kontrast ve azaltılmış hareket denenir. Her ayar sayfası için görüntü alınır; klavyeyle odaklanabilir kontrollerde yatay taşma taranır. Bu geometrik kontrol metinlerin anlamlı okunmasını veya ekran okuyucu uyumluluğunu kanıtlamaz. Görüntüler insan tarafından ayrıca incelenmelidir.

`tests/ekran.sh` yalnızca `VABU_TEST_ISOLATED=1` ile çalışır; test ortamında süreç başlatır ve kurulum arayüzü örnekleri hazırlar. Normal bilgisayarda çalıştırılmamalıdır. Bu çalışma sırasında çalıştırılmadı; GitHub'a push veya CI tetiklemesi yapılmadı.

## Güncelleme ve kurtarma sınırı

`vabu recovery-check` kurulu çekirdek sürümlerinin `/boot/vmlinuz-*`, initramfs ve modül dizinlerini salt okunur olarak karşılaştırır. Dosyaların bulunması açılışın başarılı olacağı anlamına gelmez. Kök anlık görüntüsü ayrı `/boot`, EFI ve kullanıcı verilerinin tam yedeği değildir. Otomatik tam sistem geri alma **hâlâ desteklenmiyor ve kapalıdır**; bu çalışmayla tamamlandığı iddia edilmez. Ayrıntılar [RECOVERY.md](RECOVERY.md).

Gerçek donanım denemeleri ve kök + /boot birlikte geri yükleme eksikleri burada kapanmış sayılmaz. İlgili testler geçene kadar bir `v*` sürüm yayını için kaynak commit'i, Fedora sürümü ve mimariyle eşleşen `RELEASE_VALIDATION_JSON` kaydı gerekir. Geliştirme amaçlı elle başlatılan ISO işi bu kayıtla karıştırılmaz; mevcut COPR anahtar özeti şartı ayrıca devam eder. Bu çalışmada ISO başlatılmaz.

## Yerel testler

```sh
python3 -B tests/reliability.py
python3 -B tests/desktop.py
python3 -B tests/stability.py
```

Bu değişiklikte yerel sonuç: 25 güvenilirlik + 18 masaüstü + 23 sağlamlaştırma = **66 test geçti**. Dört workflow YAML dosyası, 18 çok satırlı workflow Bash bloğu ve diff boşluk kontrolleri de doğrulandı. Fedora CI/görsel/donanım sonucu bu sayıya dahil değildir.

Testlerde sistem/paket/Wayland komutları taklittir. Dosyalar ve Unix soketleri özel geçici klasörlerdedir. Kişisel pano, oturum, disk ve ağ kullanılmaz. macOS uygulama sandbox'ı Unix soketini engelliyorsa test için yalnızca bu geçici soket erişimi gerekir; bu, gerçek hizmetleri başlatmak anlamına gelmez.

API dayanakları: [Quickshell Process](https://quickshell.org/docs/v0.2.1/types/Quickshell.Io/Process/), [Qt FocusScope](https://doc.qt.io/qt-6/qml-qtquick-focusscope.html), [niri pencere kuralları](https://niri-wm.github.io/niri/Configuration:-Window-Rules.html), [DNF5 needs-restarting](https://dnf5.readthedocs.io/en/latest/dnf5_plugins/needs_restarting.8.html), [Fedora dnf5-plugins](https://packages.fedoraproject.org/pkgs/dnf5/dnf5-plugins/).

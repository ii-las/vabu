# Masaüstü geliştirmeleri

Bu değişiklikler ayrı Codex dalında kaynak koduna eklendi. Yerel macOS üzerinde ISO üretilmedi, grafik Linux oturumu başlatılmadı, paket indirilmedi ve donanım ayarı değiştirilmedi. Kullanıcının talebiyle bu çalışma ISO veya donanım denemesi beklemiyor. Aşağıdaki işlevlerin Fedora üzerindeki görsel ve donanım doğrulaması henüz yapılmış sayılmaz.

## Eklenen işlevler

| Alan | Uygulama |
|---|---|
| İlk açılış rehberi | Altı adımlı tur; terminal, genel bakış, kısayollar ve ayarlara erişim. Tamamlandı/atlandı tercihi kaydedilir. Canlı kullanıcıya otomatik gösterilmez. |
| Sistem tepsisi | Geniş/dar panelde simgeler, birincil/ikincil eylem, sağ tık menüsü, kaydırma, erişilebilir ad ve araç ipucu. Quickshell SystemTray kullanılır. |
| Tanılama ve kurtarma | Ağ, portal, ses, Bluetooth, yazdırma, sürücü, güncelleme, kilitleme ve snapshot kontrolleri. niri ayarlarını onayla sıfırlama ve ayrı kurtarma oturumu. |
| Rapor ve ölçümler | Önizlenip kopyalanabilen paket/durum raporu; CPU süreç ortalaması, RAM ve desteklenen pil güç verileri. Kullanıcı adı, SSID, IP, seri numarası ve ham günlükler rapora alınmaz. |
| Güç yönetimi | Pilde/prizde ayrı kilit, ekran kapama ve uyku süreleri. Kilitleme kabuktan bağımsız kullanıcı hizmetindedir. Kapak politikası açık yetkilendirmeyle sistem geneline yazılır; logind yeniden başlatılmaz, sonraki açılışta uygulanır. |
| Gelişmiş bağlantılar | Blueman üzerinden PIN/onaylı eşleştirme; eşleşmeyi kaldırma; NetworkManager düzenleyicisinde gizli/kurumsal Wi-Fi ve VPN. OpenVPN/OpenConnect GNOME bütünleşme paketleri tanımlanır. |
| Cihazlar | Yazıcı, tarayıcı, disk, dosyalar ve Flatpak izin araçlarına erişim; gerekli paket bağımlılıkları. Diskler kendiliğinden biçimlendirilmez veya bağlanmaz. |
| Ekran paylaşımı | Mevcut GNOME/GTK portal bağımlılıkları ve niri oturumu kullanılır; izin ve kaynak seçimi görüşme uygulamasının portal penceresinde yapılır. Tanılama bağlantısı eklenir. |
| Erişilebilirlik | Yazı ölçeği, yüksek kontrast, azaltılmış hareket, cam efektlerini kapatma; ortak denetimlerde klavye gezinmesi ve odak göstergesi. Tam ekran okuyucu onayı değildir. |
| Dil | Türkçe/İngilizce sözlük, arayüz dili seçimi ve yerel tarih biçimleri. Sistem araçlarının kendi mesajları işletim sisteminin dilinde kalabilir. Kullanıcı metinleri çevrilmez. |
| Pencere arama | Super+Tab ile açık pencereleri başlık veya uygulama adına göre bulup odaklama. |
| Çalışma alanları | Adlandırılmış alanlar, uygulama atama/kaldırma, niri doğrulamalı kurallar ve isteğe bağlı oturum açılışı uygulamaları. Varsayılan olarak uygulamalar kendiliğinden başlatılmaz. |
| Uygulama menüsü | Sabitlenmiş simgelerde veya uygulama arama sonucunda sağ tık: yeni pencere, sabitleme, açık pencereye gitme/taşıma; algılanan harici GPU varsa başlatma. |
| Ekran profilleri | Adlandırılmış düzenleri saklama/yükleme/silme; ekran adları eşleşir, yüklenen düzen bağımsız 15 saniyelik geri dönüş koruyucusuyla denenir. Profiller kendiliğinden uygulanmaz. |
| Odak modu | Bildirimleri susturur, istenirse paneli daraltır; kapatılınca önceki panel tercihi korunur. Kritik bildirim politikası mevcut davranışını korur. |
| Pano geçmişi | Varsayılan kapalı, yalnızca metin, bellekte en fazla 20 kayıt/16 KiB; 10 dakika zaman aşımı, arama, kopyalama, silme, duraklatma ve temizleme. Kilitte temizlenir. İçerik argv veya dosyaya konmaz. |
| Kurulum geri bildirimi | Aynı anda tek uygulama kurulumu, mevcut araç çıktısına bağlı ilerleme, açıklayıcı hata ve tekrar deneme. Doğrulanmayan kaynak/parametre kabul edilmez. |
| Küçük ekranlar | Ayarlar gezinmesinde ve yan panelde kaydırma, dar ayar satırında alt alta denetimler, ayarlanabilir panel genişliği, uzun metinleri kısaltma. |
| Giriş kurtarması | Grafik greeter başarısızsa metin girişine dönüş; başarılı kimlik doğrulamadan sonra ikinci giriş başlatılmadan çıkış. Sistem klavye düzeni başlangıçta devralınır. |

## Pano gizliliğinin sınırı

`CLIPBOARD_STATE=sensitive` ve parola yöneticisi MIME işaretleri, özel anahtar başlıkları, büyük ve ikili içerikler atlanır. Hassas olduğunu işaretlemeyen bir uygulamanın düz metin parolası güvenilir biçimde tanınamaz. Bu nedenle geçmiş açık bir kullanıcı tercihidir ve kilitteki/geçersiz oturumdaki veriler kabul edilmez. Bellekte saklama, kriptografik bellek silme garantisi değildir. Pano hizmeti Wayland veri kontrol protokolü gerektirir; desteklenmezse hata gösterir.

## Kaynaklar ve API dayanakları

- [Quickshell SystemTrayItem API](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.SystemTray/SystemTrayItem/)
- [niri named workspaces](https://niri-wm.github.io/niri/Configuration:-Named-Workspaces.html)
- [niri portal bileşenleri](https://niri-wm.github.io/niri/Important-Software.html)
- [wl-clipboard hassas içerik protokolü](https://github.com/bugaevc/wl-clipboard/blob/master/data/wl-clipboard.1)

## Çevrimdışı doğrulama

```sh
python3 -B tests/reliability.py
python3 -B tests/desktop.py
```

İlk paket güvenilirlik testlerini, ikincisi yeni masaüstü özelliklerini denetler. Gerçek sistem komutlarının yerine taklit araçlar kullanılır. Pano sunucusu özel geçici soket ve taklit Wayland araçlarıyla sınanır. QML içindeki JavaScript işlevleri ayrıca derlenir; bu kontrol Qt/Quickshell bileşenlerinin çalıştığı anlamına gelmez. Fedora görsel test akışına yeni sayfalar ve rehber ekranları da eklenmiştir; bu akış burada çalıştırılmamıştır.

## Daha sonra yapılacak gerçek sistem doğrulaması

| Senaryo | Beklenen sonuç | Bu çalışma |
|---|---|---|
| Fedora RPM kurulumu, x86_64/aarch64 | Paketler ve tüm QML türleri yüklenir | Yapılmadı |
| Küçük ekran, %150 yazı, iki dil | Eylemler erişilebilir, kritik içerik taşmaz | Görsel olarak doğrulanmadı |
| Bluetooth PIN, kurumsal ağ, VPN | Sistem aracında kimlik bilgileri güvenle alınır | Donanımda denenmedi |
| Wayland ekran paylaşımı | Portal kullanıcıya kaynak seçtirir | Canlı oturumda denenmedi |
| Kilit, uyku/uyanma, kapak ve kabuk çökmesi | Oturum kilidi korunur; zamanlama kabuktan bağımsızdır | Taklit test + gerçek donanım bekliyor |
| Calamares kurulumu ve yeniden açılış | ISO çıkarıldıktan sonra kurulan sistem açılır | Kullanıcı talebiyle yapılmadı |
| Güncelleme sonrası açılış ve kurtarma | Çekirdek/modül/açılış zinciri tutarlı kalır | Yapılmadı; otomatik tam sistem geri alma kapalı |
| Performans/pil karşılaştırması | Aynı donanımda tekrarlanabilir ölçüm | Ölçüm aracı eklendi, kıyaslama yapılmadı |

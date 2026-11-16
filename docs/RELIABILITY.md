# Güvenilirlik değişiklikleri ve doğrulama sınırı

Bu dal, masaüstü ve sistem araçlarındaki hata yönetimini iyileştirir. macOS üzerinde gerçek Fedora oturumu veya ISO kurulumu yapılmamıştır. Ana çalışma klasörü değiştirilmeden ayrı Git worktree kullanılmıştır. Yerel doğrulamada paket indirilmez, sistem hizmeti başlatılmaz, ekran veya disk ayarı değiştirilmez.

## Yerel regresyon testleri

Gerekenler: mevcut Python 3, Node.js ve Bash. Ek Python veya Node paketi gerekmez.

```sh
python3 -B tests/reliability.py
```

Testler özel geçici klasörlerde çalışır. niri, dnf, sudo, pkexec, snapper, systemctl, kilit ve başlatıcı komutları taklit edilir. Ekran önizlemesinin bağımsız koruyucusu bu taklit niri ile çalıştırılır. Süre dolması, açık geri dönüş, onay, kısmi uygulama hatası, eşzamanlı önizleme ve geçersiz girişler denetlenir. Kilit isteği ile compositor onayı ayrılır; onay yoksa yedek kilit denenir. JavaScript arama ve nmcli kaçış ayrıştırma mantığı da kontrol edilir.

## Davranış değişiklikleri

- Güncelleme sorgusu başarısızsa “Her şey güncel” gösterilmez. DNF'nin 100 çıkış kodu güncelleme bulunduğu anlamında kabul edilir. İki sorgu da tamamlanmadan denetim bitmiş sayılmaz.
- Ekran değişiklikleri sırayla uygulanır. Ayrı, yetkisiz koruyucu süreç onaysız değişikliği 15 saniye sonra geri alır; Ayarlar sayfasının veya uygulamanın kapanmasına bağlı değildir. Aynı oturumda ikinci önizleme reddedilir. Donanımın sökülmesi veya compositor'ın yanıt verememesi hâlinde geri dönüş mutlak garanti değildir.
- Çalışan kökte `snapper undochange` kullanan eski `vabu rollback` durdurulur. `/boot` ve kök birlikte güvenle kurtarılmadan tam sistem geri alma sunulmaz. Anlık görüntüler silinmez; listeleme devam eder.
- Fedora sürüm makroları Vabu release paketinde sağlanır. Sürücü aracı taban sürümü os-release üzerinden bulur. Kurulu ama yüklenmemiş NVIDIA modülü artık kesin olarak “yeniden başlatma bekliyor” diye tanımlanmaz.
- Başlatıcı IPC hatasında fuzzel'e geçer. Yedek masaüstü araçları açık bağımlılıktır. Kabuk çalışma sırasında çökerse de hata kaydı gösterilir.
- Sistem güncelleme zamanlayıcısı RPM indirir; sistem Flatpak uygulamalarını sessizce kurmaz. Kullanıcı Flatpak zamanlayıcısı mevcut davranışıyla ayrıdır.
- Firefox RPM olarak hazır gelir. Diğer varsayılan Flatpak uygulamalarının ilk kurulumunda hâlâ internet gerekir.
- Ortak düğmeler ve anahtarlar Tab, Enter ve Space ile kullanılabilir; odak göstergeleri vardır. Bu, tam ekran okuyucu uyumluluğu onayı değildir.

## Derleme ve sürüm takibi

RPM ve Quickshell CI ortamları FEDORA_VERSION ile aynı Fedora sürümünü kullanır. Kaynak arşivine LICENSE eklenir ve Vabu RPM'lerine kurulur. Üç çekirdek Vabu paketi kaynak commit'ini Provides olarak taşır; desktop paketi aynı sürüm ve Release'teki shell/release paketlerini ister. Commit bilgisi spec içine yazılır, böylece COPR'da SRPM yeniden derlenirken kaybolmaz.

GitHub ISO işi gerekli kaynak commit'ini imaj tanımına yazar; Kiwi config.sh kurulan Vabu paketlerinin bu commit'i sağladığını denetler. Uyuşmazlıkta derleme durur. RPM kaynak commit'i bilinmeyen yerel paketler `unknown` olarak işaretlenir. Yerel `just iso` bu GitHub kontrolünü kendiliğinden eklemez. İmajdaki paket listesi `/usr/share/vabu/build-packages.txt` içine kaydedilir. Bu liste bütün üçüncü taraf paketleri sabitleyen bir kilit dosyası değildir.

## Fedora üzerinde tamamlanması gereken kontroller

- RPM derleme/kurulum, makrolar, paket bağımlılıkları ve COPR kaynak commit kontrolü.
- Quickshell ile QML yükleme ve gerçek NetworkManager/PipeWire etkileşimi; Türkçe ortam.
- Ekran önizlemesinde sayfa kapatma, uygulama sonlandırma, ekran sökme/takma ve çoklu ekran.
- Gerçek PAM doğrulaması, kilit çökmesi, uyku/uyanma ve Secure Boot/MOK.
- Calamares ile şifreli/şifresiz kurulum, ISO çıkarıldıktan sonra açılış; x86_64 ve aarch64.

Sonraki masaüstü geliştirmeleriyle ISO tanımında RPM imza doğrulaması açılmıştır. Doğrulanmış COPR anahtar özeti olmadan derleme durur; imzalı kaynak doğrulaması olmadan sürüm yayınlanmaz. Bu akış bu bilgisayarda çalıştırılmamıştır. Ayrıntılar: [ISO_TRUST.md](ISO_TRUST.md). Masaüstü özellikleri ve kalan gerçek sistem testleri: [DESKTOP_FEATURES.md](DESKTOP_FEATURES.md). Otomatik tam sistem geri alma hâlâ devre dışıdır.

# Son masaüstü genişletmesi ve doğrulama sınırı

Çalışma ayrı Codex dalındadır. Ana dal değiştirilmez; paket indirme/kurma, gerçek güncelleme, ISO üretimi, sanal makine veya donanım işlemi bu çalışma sırasında başlatılmaz. Yeni kaynakların Fedora üzerindeki gerçek açılışı henüz doğrulanmış değildir.

## Dört hata düzeltmesi

- Güç süreleri, listede olmayan geçerli bir değeri de seçeneklere katar. Örneğin 1 veya 120 dakika artık Asla olarak sunulmaz.
- İlk açılış turu, ayarlar başarıyla okunmadan başlamaz. Bozuk ayar dosyası da turu kendiliğinden açmaz.
- `/boot` mount sorgusu başarısızsa ayrı bölüm durumu bilinmiyor olur.
- Statik QML denetimi, aracın gerçek çıkış kodunu korur. Eksik ikili veya seçili metin listesine girmeyen hata başarı sayılmaz. Bu akış burada çalıştırılmadı; testte taklit lint ikilisinin hata kodu doğrulandı.

## Eklenen özellikler

| Özellik | Davranış ve sınır |
|---|---|
| Kısayol düzenleyicisi | 12 mevcut eylem; Super içeren tuşlar, yönetilen kısayollarla çakışma kontrolü, bilinen tuş adları, tek veya toplu varsayılana dönüş. İçe aktarılan ayardan özel komut çalıştırılmaz. Sabit kilitleme kısayolu korunur. Kişisel KDL bölümü yeniden yazılmaz; niri doğrulaması son kontroldür. |
| Güncel kısayol rehberi | Yönetilen kısayollar rehberde gösterilir. Dar ekranda sütunlar alt alta geçer ve içerik kaydırılır. Elle yazılmış kullanıcı KDL kuralları rehber tarafından yorumlanmaz. |
| Ayar aktarımı | Masaüstü ve pencere ayarları ayrı JSON dosyalarıdır. Dosya seçimi, önce/sonra önizlemesi ve açık kullanıcı onayı vardır. Dosya veya mevcut ayarlar değişirse eski onayla uygulama reddedilir. Son sağlam dosya yedeklenir. |
| Aktarım mahremiyeti | Parolalar, pano ve pano izni, konum, oturum başlatma izni, aktif odak süresi, ham KDL ve canlı ekran düzeni aktarılmaz. Desteklenmeyen alanlar sessizce kabul edilmez. Profil adları, çalışma alanları ve uygulama listeleri kullanıcı tercihidir; dosyayı paylaşmadan önce incele. |
| Uygulama bildirimleri | Göster, sessiz ve engelle. Sessiz, merkezde saklar; engelle kritik bildirimleri de gizler. Normal odak modu kritik bildirimlerin mevcut davranışını korur. Kimlik bildirim gönderen uygulama tarafından sağlandığından bu bir güvenlik izni değildir. |
| Süreli odak | 25/50/90 dakika ve erken bitirme. Bitiş zamanı kaydedilir; önceki normal panel tercihi korunur. Sistem saatinin değişmesi süreyi etkileyebilir. |
| Ekran kimlikli profiller | Üretici/model/seri bilgisinden yerel özet oluşturulur; ham seri numarası saklanmaz. Bağlantı adı değişince aynı ekran bulunabilir. Eksik, çoğul veya belirsiz eşleşme otomatik uygulanmaz. Eski profiller bağlantı adıyla açılır ve uyarı verir. Yükleme yalnızca taslağı değiştirir; uygulama 15 saniyelik korumayla ayrıca denenir. Özet anonimlik garantisi değildir. |
| Ortak güncelleme geçmişi | Elle güncelleme, sistem indirme zamanlayıcısı, kullanıcı Flatpak/Distrobox zamanlayıcısı ve DNF işlem kancaları. Son 50 kayıt; kaynak, zaman, durum ve sınırlı çıkış kodları. Ham günlükler, paket komut satırı ve kimlik bilgileri saklanmaz. Kullanıcı kayıtları özel, sistem kayıtları yalnızca sabit durum verisidir. |
| DNF kaydının sınırı | Ön kanca Başlatıldı, son kanca İşlem sonu kaydedildi der. Kanca gözlemi kesin işlem başarısı veya tam sistem yedeği olarak gösterilmez. Gerçek çıkış kodunu gören elle/zamanlayıcı yardımcıları başarı ve hatayı ayırır. Takip hatası paket işlemini durdurmaz. |
| Snapshot/disk görünümü | Kök boş alanı, okunabilen Snapper alanları ve saklama politikası. Paylaşılan bloklar toplanmaz; qgroup/izin/araç eksikliği sıfır kullanım diye gösterilmez. Silme, temizlik veya kota değişikliği yapılmaz. |
| Masaüstü ölçümü | Kullanıcının başlattığı 10 örnek; son 12 kayıt, RAM ve desteklenen pil gücü, systemd açılış süresi. CPU süreç ömrü ortalamasıdır. Aynı cihaz/parlaklık/güç kaynağı/iş yüküyle değerlendirilmelidir. VM ölçümü gerçek pil ömrünü kanıtlamaz; bu çalışma gerçek performans sonucu üretmedi. |

Yeni ekranların Türkçe/İngilizce metinleri eklendi. Ayar aktarımı, bildirim sayfası ve güncel kısayol rehberi Fedora ekran akışına dahil edildi. FileDialog için Qt Quick Dialogs kullanılır; gerçek portal/Qt yüklemesi Fedora denemesinde ayrıca kontrol edilmelidir.

## Daha büyük işlerin durumu

- Gerçek QML/Fedora kontrolü için CI akışı hazırlanmıştır; buradan GitHub'a push veya workflow tetiklemesi yapılmadı.
- Güncelleme kanalları ortak geçmişe bağlandı. Başka araçların RPM dışındaki her işlemini gözlemleme garantisi yoktur.
- Performans için tekrarlanabilir sınırlı örnekleme vardır; gerçek karşılaştırma sonucu yoktur.
- Görsel/erişilebilirlik senaryoları hazırlanmıştır; insan incelemesi, ekran okuyucu ve donanım doğrulaması yapılmış sayılmaz.
- **Kök + /boot birlikte geri yükleme motoru yazılmadı; otomatik tam sistem geri alma kapalıdır.** Bu, kalan büyük bir iştir. Snapshot listesi veya dosya envanteri bu eksikliği kapatmaz. [Kurtarma kapsamı](RECOVERY.md).
- Kullanıcının istediği sıra korunur: önce kaynak çalışması, sonra kullanıcının ISO hazırlığı, ardından sanal makine doğrulaması. [VM doğrulama planı](VM_VALIDATION.md).

## Çevrimdışı testler

```sh
python3 -B tests/reliability.py
python3 -B tests/desktop.py
python3 -B tests/stability.py
python3 -B tests/expansion.py
```

Yerel sonuç: 25 güvenilirlik + 18 masaüstü + 23 sağlamlaştırma + 26 genişletme = **92 test geçti**. Dört workflow YAML dosyası, 18 çok satırlı Bash bloğu, yeni yardımcıların sözdizimi/çalıştırılabilirliği ve staged diff boşlukları kontrol edildi. Bu sayıya Fedora CI, gerçek Qt yüklemesi, VM veya donanım denemesi dahil değildir.

Sistem ve Wayland komutları taklit edilir. Ayarlar ve kayıtlar özel geçici klasörlerde oluşturulur. Root çalışan CI testlerinde de kayıtlar gerçek `/var/lib` dizinine gitmez. Grafik oturum veya gerçek kullanıcı panosu açılmaz. Kaynak/test başarısı, Fedora donanım uyumluluğu anlamına gelmez.

API dayanakları: [Qt FileDialog](https://doc.qt.io/qt-6/qml-qtquick-dialogs-filedialog.html), [Quickshell Notification](https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Notifications/Notification/). Diğer dayanaklar [sağlamlaştırma kaydında](STABILIZATION.md).

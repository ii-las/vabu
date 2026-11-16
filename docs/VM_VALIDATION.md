# ISO sonrasında sanal makine doğrulaması

Bu belge bir test planıdır; test sonucu değildir. Bu çalışma ISO üretmez veya VM başlatmaz. Önce ISO güven şartları hazırlanmalı; sonra test edilecek kaynak commit'i, Fedora sürümü ve mimari kaydedilmelidir.

## Ortam

İlk deneme yalnızca boş sanal diskle ve kişisel dosyalar paylaşılmadan yapılmalı. Kurulu VM'nin soğuk yedeği/snapshot'ı test ortamının dışında tutulmalı. Bir mimarideki sonuç başka mimariye taşınmaz. VM; fiziksel Bluetooth, ekran sökme/takma, kapak, gerçek pil ve Secure Boot/MOK donanım senaryolarının tamamını kanıtlamaz.

## Sıra ve beklenen sonuç

1. **Kurulum ve açılış:** Hesap ekranındaki ad, kullanıcı adı, bilgisayar adı ve iki parola alanına fareyle tıklayıp yazın; Tab ile gezin. Farklı parolalarda ileri engellenmeli, eşleşince açılmalı. Yerleşik `users` formu kullanılır; `usersq` etkin değildir. CI her iki mimaride aynı formu kurulum işi içermeyen izole Wayland oturumunda gerçekten yazarak sınar; bu kontrol VM kurulumunu kanıtlamaz.

    şifreli/şifresiz kurulum; ISO çıkarıldıktan sonra açılış. Hedef yalnızca sanal disk olmalı. Kaynak RPM sürümleri ve QML yükleme hataları incelenmeli.
2. **İlk açılış:** tamamlanan rehber ikinci girişte açılmamalı. Ayar yüklenmesi gecikince veya dosya bozulunca rehber yanlışlıkla başlamamalı.
3. **Küçük ekran/dil:** Türkçe ve İngilizce; 800×600 Ayarlar, %150 yazı, yüksek kontrast ve azaltılmış hareket. Tüm eylemlere Tab/Enter/Space ile erişilmeli; metinler ve hata açıklamaları okunmalı. Statik geometri kontrolü insan incelemesinin yerine geçmez.
4. **Kısayollar:** bir eylemi değiştir, rehberle karşılaştır, varsayılana dön. Sabit bir tuşla çakışma reddedilmeli; kilit kısayolu korunmalı. Kişisel KDL bölümü değişmemeli.
5. **Aktarım:** iki ayar grubunu ayrı dışa aktar. Önizleme öncesi hiçbir tercih değişmemeli. Dosya veya mevcut ayarlar önizleme sonrasında değiştirilince uygulama reddedilmeli. Pano izni, konum ve otomatik başlatma aktarılmamalı.
6. **Bildirim/odak:** göster/sessiz/engelle ve kritik bildirimleri dene. Odak süresi bitince önceki panel tercihi gelmeli; engellemenin kritik bildirimleri de gizlediği açık olmalı.
7. **Güncelleme:** çevrimdışı depo, iptal edilen yetkilendirme, RPM hatası ve kısmi Flatpak hatası başarı sayılmamalı. Zamanlayıcı ve DNF kayıtları görünmeli; DNF son kancası kesin başarı gibi gösterilmemeli.
8. **Ekran profili:** yükleme kendiliğinden uygulamamalı. Deneme onaysız kalınca bağımsız koruyucu geri dönmeli; Ayarlar'ın kapanması bunu durdurmamalı. Gerçek kimlik/bağlantı değişimi fiziksel veya uygun sanal ekran ortamında ayrıca denenmeli.
9. **Kilit/kurtarma:** kilit onayı ve uyku/uyanma; kabuk kapanınca bağımsız kilitleme. Temel kurtarma oturumu ve önceki çekirdek denenmeli. Deneysel çevrimdışı motor [RECOVERY_ENGINE.md](RECOVERY_ENGINE.md) sırasıyla ayrı disk yedeği üzerinde denenmeli; gerçek apply/resume/undo ve kesintiler geçmeden offline-rollback başarılı yazılmamalı.
10. **Disk/ölçüm:** Snapper alanı bilinmiyorsa sıfır görünmemeli; bu sayfa temizlik yapmamalı. Ölçüm yoksa bilinmiyor denmeli; VM pil verisi gerçek donanım sonucu sayılmamalı.

Başarısızlıkta VM'nin ayrı yedeğinden dönülmeli; çalışan köke gelişigüzel snapshot uygulanmamalı. Tam kök + /boot geri yükleme için ayrıca tasarım, uygulama ve kesinti senaryoları gerekir.

Sonuçlar ve kanıt bağlantıları, `RECOVERY.md` içindeki kaynak/mimari/Fedora eşleşmeli yayın kaydına ancak testler gerçekten geçtikten sonra yazılır. Şu anda hiçbir senaryo geçmiş olarak işaretlenmemiştir.

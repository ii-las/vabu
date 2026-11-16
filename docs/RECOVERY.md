# Kurtarma kapsamı ve gerçek test kaydı

## Mevcut destek

- Vabu Kurtarma oturumu, kişisel niri ayarı ve Vabu Shell yerine paketlenmiş temel panel/terminali kullanır.
- `vabu reset niri`, eski ayarları yedekleyerek masaüstü ayarını sıfırlar.
- `vabu snapshots`, kök dosya görüntülerini listeler.
- `vabu recovery-check`, çekirdek, initramfs ve modül dosyalarının varlığını inceler; disk bağlamaz, GRUB/dracut çalıştırmaz ve dosya geri yüklemez.
- `vabu rollback` çalışan sistemde değişiklik yapmadan hata verir. Çalışan köke `snapper undochange` uygulanmaz.
- `vabu recovery` artık deneysel çevrimdışı create/list/plan/apply/resume/undo motorudur. Desteklenen düzen ve güvenlik sınırı: [RECOVERY_ENGINE.md](RECOVERY_ENGINE.md).

## Tam geri alma neden kapalı

Varsayılan kurulumda btrfs kökün yanında ayrı ext4 `/boot` ve EFI bölümü vardır. Kökü eski sürüme alıp /boot'u güncel bırakmak RPM veritabanı, çekirdek, initramfs ve sürücü modüllerini farklı sürümlerde bırakabilir. Aynı şekilde btrfs snapshot'ı, ayrı `/home` veya harici disklerdeki kullanıcı verilerini kendiliğinden korumaz.

Güvenilir tam geri alma için aynı işlem kimliğine bağlanmış kök + /boot/EFI yedekleri, bütünlük doğrulaması, yeterli boş alan, desteklenen bölüm/LUKS düzeni, çalışan sistem dışında uygulama ve kesinti sonrası yeniden başlatılabilir bir işlem gerekir. Bu şartlar için deneysel çevrimdışı motor eklendi. Gerçek Btrfs/EFI/LUKS ve önyükleme denemeleri yapılmadığından üretim desteği verilmez; otomatik geri alma kapalı kalır.

## Sorun olduğunda izlenecek yol

1. Yalnızca kabuk/ayar sorunu varsa giriş ekranından Vabu Kurtarma oturumunu seç; önce salt okunur denetimleri incele.
2. Güncelleme sonrasında yeni çekirdek açılmıyorsa GRUB'da önceki çekirdek seçeneğini dene. Bu seçenek veya açılış başarısı burada doğrulanmış değildir.
3. Sistem hiç açılmıyorsa çalışan sisteme rastgele kök snapshot'ı geri yazma. Doğrulanmış kurtarma ortamı ve gerçek bölüm düzeniyle ayrı inceleme gerekir.
4. Kullanıcı verileri, `/boot`/EFI ve şifreleme kurtarma bilgileri için sistemden bağımsız yedek gerekir. Şifre/parola/özel anahtar veya ham donanım günlüklerini paylaşılabilir rapora ekleme.

## Sürüm öncesi gerçek testler

Aşağıdaki senaryoların **tamamı henüz bekliyor**. Çevrimdışı taklit testler bunların yerine geçmez.

| Kayıt anahtarı | Gereken doğrulama |
|---|---|
| rpm-qml | Aynı kaynak RPM'leriyle kurulum, tüm QML türleri ve ayar sayfalarının gerçek yüklenmesi |
| small-screen-accessibility | İki dil, dar ekran, %150 yazı, klavye odağı ve ekran görüntülerinin okunabilirlik incelemesi |
| lock-suspend | Kilit onayı, kabuk çökmesi, uyku/uyanma ve kapak; kilit hatasında elle uyku isteğinin durması |
| display-hotplug | İki ekran, sayfa/uygulama kapatma, süre dolması ve ekran sökme/takma |
| network-bluetooth | Wi-Fi, VPN ve onay/PIN gerektiren eşleştirme |
| portal-sharing | Gerçek görüşme uygulamasında izin/kaynak seçimi ve paylaşımın kapatılması |
| install-boot | Şifreli/şifresiz kurulum; kurulum ortamı çıkarıldıktan sonra yeniden açılış |
| offline-rollback | Eşleştirilmiş kök/boot/EFI noktası, gerçek apply/resume/undo, kesinti ve diğer EFI/kullanıcı verilerinin korunması |
| update-recovery | Başarılı/başarısız güncelleme, çekirdek/modül tutarlılığı, önceki çekirdek ve temel kurtarma oturumu; çevrimdışı motorun deneysel ve VM doğrulaması bekleyen durumunun doğru belirtilmesi |

Her mimari ayrı kaydedilir. Bir x86_64 denemesi aarch64 için başarı sayılmaz. Donanım modeli ve test koşulları kanıtta belirtilmelidir; tüm donanımlar için garanti çıkarılamaz.

## Yayın kapısı

Gerçek testlerden sonra depo yöneticisi GitHub repository variable `RELEASE_VALIDATION_JSON` içine şu biçimde bir kayıt koyabilir. Bu örnek **bilerek geçersizdir**, başarı kaydı değildir:

```json
{
  "format": 1,
  "sourceCommit": "TEST_EDILEN_TAM_COMMIT",
  "fedora": "45",
  "architectures": {
    "x86_64": {
      "rpm-qml": {"status": "pending", "evidence": ""}
    }
  }
}
```

`tools/validate-release.py` tüm tablo anahtarları için `passed` ve HTTPS kanıt bağlantısı ister. Commit, Fedora ve mimari birebir uyuşmalıdır. Kayıt kaynağın dışında tutulur; böylece test kaydı eklemek test edilen commit'i değiştirmez. İşlem insanın beyanını ve kaydın eksiksizliğini denetler; kanıtın gerçekliğini kendiliğinden kanıtlamaz. Eksik kayıt `v*` etiketli ISO/yayın işini derlemeden önce durdurur. Bu değişiklik herhangi bir kayıt oluşturmadı, GitHub değişkeni ayarlamadı veya yayın başlatmadı.

Son hata düzeltmeleri ve yeni özelliklerin kapsamı: [DESKTOP_EXPANSION.md](DESKTOP_EXPANSION.md). ISO sonrası deneme sırası: [VM_VALIDATION.md](VM_VALIDATION.md).

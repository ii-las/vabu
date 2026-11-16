# Çevrimdışı tam sistem geri alma motoru

Bu motor kaynakta uygulanmıştır; gerçek Btrfs/EFI/LUKS veya önyükleme doğrulaması henüz yapılmamıştır. İlk kullanım yalnızca ayrı yedeği olan, kişisel veri içermeyen test VM'sinde yapılmalıdır. ISO bu çalışma sırasında üretilmedi. Yazma komutları deneysel kullanım kabulü ister; otomatik geri alma ve otomatik yeniden başlatma yoktur.

## Desteklenen kapsam

- Canlı ISO ile açılmış Linux, root yetkisi ve PID 1 ile aynı mount namespace.
- Üç açık hedef: btrfs `subvolid=5` üst hacmi, ayrı ext4 `/boot`, vfat EFI.
- Kök alt hacim adı `root`; `/home` ve `/var/log` ayrı btrfs alt hacimleri. ext4 kök, BIOS, LVM ve farklı alt hacim düzenleri reddedilir.
- Kök, fstab ve BLS üzerinden `subvol=root` adıyla açılmalıdır. Sabit `subvolid` ile açılan kurulum reddedilir.
- LUKS2 kullanılıyorsa kullanıcı canlı ortamda eşleyiciyi önceden açmış olmalıdır. Motor parola istemez, LUKS açmaz/biçimlendirmez. Başlığın yalnızca değişim özeti kayda bağlanır; başlık/anahtar yuvaları değişmişse nokta uygulanmaz. BLS kökü eşleyici adıyla belirtiyorsa o ad canlı ortamda bulunmalıdır.
- Yönetilen EFI kapsamı Calamares ayarındaki `EFI/fedora` dizinidir. Başka EFI üreticileri, `EFI/BOOT`, firmware NVRAM girdileri, bölüm tablosu ve LUKS başlıkları geri yazılmaz.
- `/home`, ayrı `/var/log` ve diğer EFI üretici dizinleri korunur. Kök içindeki `/etc` ve `/var` verileri seçilen tarihe döner. Ayrı veri yedeğinin yerini tutmaz.

Bu nedenle “tam sistem” burada Vabu'nun desteklenen OS kökü ve eşleşen birincil önyükleme zinciridir; tüm disk veya firmware görüntüsü değildir. Aynı diskteki btrfs görüntüsü disk arızasına karşı bağımsız yedek değildir.

## Güvenlik kontrolleri

Motor disk keşfedip kendiliğinden bağlamaz; kullanıcı açık mount yollarını seçer. UUID, dosya sistemi türü, FSROOT, aygıt numarası, fstab, makine kimliği ve BLS kök hedefi doğrulanır. Üç mount iç içe olamaz. Mount dizinleri root sahipliğinde ve başka kullanıcıya yazılamaz olmalıdır; vfat EFI root sahipliği ve `umask=0077` gibi kısıtlı izinlerle bağlanmalıdır. Kurulumun başka yerde bağlı olması, hedef altında ek mount veya başka süreç namespace'inde hedefin kullanılması reddedilir. macOS, normal kurulu sistem ve konteynerde motor yazmadan durur.

Kurtarma deposu üst hacimde `.vabu-recovery` altında root'a özel tutulur. Kök salt okunur btrfs görüntüsüdür; UUID, nesil ve salt okunur durum doğrulanır. `/boot` ve `EFI/fedora` kopyalarında dosya/link/dizin envanteri ve SHA-256 kullanılır. Kopya, EFI stub'u, normal BLS girdileri, kökteki vmlinuz ve `/boot` vmlinuz eşleşir. Eski Snapper numarası bu kayıtların yerine geçmez.

Bir işlem hedefi değiştirmeden önce tüm yeni önyükleme verisini hazırlar, alanı denetler, gerçek alt hacimler üzerinde atomik exchange yeteneğini sınar ve günlüğü diske eşitler. Sonra önyükleme adımları eski kopyalar saklanarak uygulanır; kök adı en son atomik olarak değiştirilir. Bölümler arasında tek atomik işlem mümkün değildir: elektrik kesilirse kurulu sistemi açmadan canlı ISO'da devam/geri dönüş tamamlanmalıdır.

Yeni kökte Snapper için boş `.snapshots` alt hacmi hazırlanır ve SELinux yeniden etiketleme işareti konur. Eski kök ve eski Snapper ağacı işlem dizininde korunur; eski Snapper listesi yeni kökte kendiliğinden görünmez. Altı kurtarma noktası ve altı işlem sınırı vardır; hiçbir nokta, eski kök veya geri dönüş kopyası kendiliğinden silinmez. Bakım/temizlik ayrıca incelenmelidir.

## Komutlar: yalnızca ilerideki test VM'sinin canlı ISO oturumunda

Aşağıdaki yollar kullanıcı tarafından doğru VM bölümleriyle **önceden bağlanmış** olmalıdır. Burada aygıt adı uydurulmaz ve bağlama komutu otomatik verilmez. Hedef kök başka bir mount altında bağlı olmamalıdır. Mac üzerinde bu geri alma komutlarını çalıştırma.

```sh
# Güncelleme ÖNCESİNDE canlı ortamda eşleşmiş tam nokta oluştur:
sudo vabu recovery create --top /mnt/vabu-top --boot /mnt/vabu-boot --efi /mnt/vabu-efi --label "Before update"

# Kimlikleri ve varsa yarım kalan işlemleri listele:
sudo vabu recovery list --top /mnt/vabu-top --boot /mnt/vabu-boot --efi /mnt/vabu-efi

# Daha sonra yine canlı ISO'da salt okunur plan al:
sudo vabu recovery plan NOKTA_KIMLIGI --top /mnt/vabu-top --boot /mnt/vabu-boot --efi /mnt/vabu-efi

# Yalnızca planın hedefleri ve kapsamı incelendikten sonra:
sudo vabu recovery apply NOKTA_KIMLIGI --top /mnt/vabu-top --boot /mnt/vabu-boot --efi /mnt/vabu-efi --confirm PLANDAKI_ONAY_OZETI --ack-unverified

# İşlem yarım kaldıysa list'teki işlem kimliğiyle devam et:
sudo vabu recovery resume ISLEM_KIMLIGI --top /mnt/vabu-top --boot /mnt/vabu-boot --efi /mnt/vabu-efi --confirm ISLEM_KIMLIGI --ack-unverified

# Aynı işlemi önceki durumuna geri çevir:
sudo vabu recovery undo ISLEM_KIMLIGI --top /mnt/vabu-top --boot /mnt/vabu-boot --efi /mnt/vabu-efi --confirm ISLEM_KIMLIGI --ack-unverified
```

`plan` hiçbir dosya oluşturmaz ve onay özeti değişmiş hedefte kabul edilmez. `apply` bir işlem kimliği kaydeder. Yarım kalmış işlemi yeni bir apply ile atlama. `resume`/`undo` kayıtlı adımların hangi atomik hareketten sonra kesildiğini dosya durumundan çıkarır; beklenmeyen değişiklikte durur. `undo` geri alma öncesindeki duruma döner; o durum zaten bozuksa onu düzeltmiş sayılmaz. Bütünlük uyuşmazlığında rastgele dosya silip kontrolü atlama.

Nokta oluşturmak da başlangıçta çevrimdışıdır. Normal DNF işlemlerinin mevcut Snapper noktaları otomatik olarak bu tam noktalara dönüşmez. Bir tam nokta oluşturulmadan geçmiş `/boot`/EFI içeriği sonradan uydurulamaz.

## Test kanıtı ve kalan doğrulama

`tests/recovery.py`, özel normal dizinlerde sahte Btrfs alt hacimleriyle çalışır. Kök/boot/EFI uygulama ve tersine dönüş, her simüle snapshot/sync/exchange sınırı, her boot rename, yanlış hedef, bozuk veri, yol kaçışı, salt okunur hedef, düşük alan ve çalışan sistem retleri denenir. Gerçek mount, blok aygıtı, EFI/NVRAM veya host `/boot` kullanılmaz. Bu mantık kanıtı gerçek dosya sistemi ve elektrik kesintisi kanıtı değildir.

Yerel son doğrulama: 25 güvenilirlik + 18 masaüstü + 23 sağlamlaştırma + 26 genişletme + 31 geri alma + 4 açık anahtar hazırlığı = **127 test geçti**. Ayrıca 29 Python kaynağı, 16 shell betiği, dört workflow YAML dosyası ve 18 çok satırlı Bash bloğu sözdizimi kontrolünden geçti. Bunlar Fedora paket derlemesi, Qt yüklemesi veya gerçek VM sonucu değildir.

VM'de ayrıca: varsayılan şifreli/şifresiz kurulum, gerçek snapshot exchange, LUKS başlık değişiminde ret, iki farklı boot/kernel sürümünü geri alma, her kesinti noktasında cold restart + resume/undo, SELinux etiketleme, eski Snapper ağacının korunması, firmware'den açılış ve diğer EFI dizinlerinin değişmemesi doğrulanmalıdır. `offline-rollback` yayın testi bunlar gerçekten geçmeden başarılı kaydedilmez.

Dayanaklar: [btrfs subvolume](https://btrfs.readthedocs.io/en/latest/btrfs-subvolume.html), [renameat2](https://man7.org/linux/man-pages/man2/rename.2.html). Çevrimdışı testler çalışsa da VM testi bekleyen bu motor için üretim güvenliği garantisi verilmez.

# Vabu

Fedora tabanlı bir Linux dağıtımı. Masaüstü olarak [niri](https://github.com/YaLTeR/niri) ve onun üzerinde çalışan kendi kabuğumuz Vabu Shell geliyor.

Vabu klasik bir Fedora sistemi: `dnf`, RPM dosyaları ve Flathub doğrudan çalışır. Fedora ve RPM Fusion depoları kurulumla birlikte açık gelir.

## Özellikler

- **Vabu Shell** ([Quickshell](https://quickshell.org) ile yazıldı): yan panel (saat, çalışma alanları, uygulamalar, medya), yan panelden açılan Wi-Fi, Bluetooth, ses, takvim, bildirim ve kontrol merkezi panelleri, uygulama başlatıcı, kilit ve giriş ekranı
- **Çalışma alanları:** yan panelde her alan, içindeki pencerelerin simgeleriyle görünür. Yön tuşları kolonlar, pencereler ve alanlar arasında tek bir haritada gezer; `Super + O` genel bakışı açar.
- **Başlatıcıdan uygulama kurma:** `kur:` yazınca Fedora, RPM Fusion ve Flathub'da arar
- **Vabu Ayarlar:** görünüm, ekranlar, ağ, Bluetooth, ses, sürücüler, depolar, güncellemeler, klavye, kullanıcılar
- **Sürücüler:** `vabu-drivers` ekran kartını algılar. NVIDIA (RPM Fusion akmod ve MOK anahtar hazırlığı), AMD ve Intel için video hızlandırma ve codec'leri kurar.
- **Anlık görüntüler:** Snapper yapılandırılmış Btrfs kökte dnf işlemlerine anlık görüntü kancaları eklenir. Ayrı `/boot` bölümü kapsam dışındadır; otomatik tam sistem geri alma henüz desteklenmez. `vabu snapshots` ile listeleyebilirsin.
- **Kurulum:** Calamares, Vabu ekranlarıyla

## Paketler

| Paket | |
|---|---|
| `vabu-release` | os-release ve Vabu deposu (`fedora-release` yerine geçer) |
| `vabu-desktop` | Masaüstü bileşenleri, varsayılan ayarlar, `vabu` ve `vabu-drivers` |
| `vabu-shell` | Vabu Shell, Vabu Ayarlar, giriş ekranı |
| `vabu-fonts` | Hanken Grotesk, Material Symbols; terminal için JetBrains Mono |
| `quickshell` | Fedora depolarında olmadığı için ayrıca paketleniyor |

Paketler [COPR](https://copr.fedorainfracloud.org/coprs/ii-las/vabu/) üzerinde derleniyor.

## Derleme

Her şey GitHub Actions'ta derleniyor:

- `rpm.yml`: paketleri derler, niri ayarlarını doğrular, kabuğu başsız bir oturumda çalıştırıp ekran görüntülerini alır, COPR'a gönderir
- `quickshell.yml`: Quickshell'i COPR'a gönderir (haftalık olarak da yeniden derler)
- `iso.yml`: Kiwi ile canlı/kurulum ISO'su üretir (x86_64, aarch64)

Bir Fedora makinede yerel olarak derlemek için [docs/BUILDING.md](docs/BUILDING.md) dosyasına bak.

## Dizinler

```
shell/         Vabu Shell, Ayarlar ve giriş ekranı (QML)
shell-system/  vabu-shell paketinin sistem dosyaları
rootfs/        vabu-desktop paketinin dosyaları
branding/      logo, duvar kağıtları, önyükleme menüsü teması
packaging/     RPM spec dosyaları
iso/           Kiwi ISO tanımı ve Calamares ayarları
tests/         kabuğu başsız çalıştırıp ekran görüntüsü alan test
tools/         duvar kağıdı üreticisi
```

## niri ayarı

`~/.config/niri/config.kdl` dosyası `/usr/share/vabu/niri/config.kdl.in` şablonundan üretilir. Vabu Ayarlar değişiklikleri `~/.config/vabu/niri.json` dosyasına yazar.

- Üretilen dosya kaydedilmeden önce `niri validate` ile denetlenir.
- Dosyanın sonundaki "Kendi eklemelerin" bölümü korunur.
- İlk satırdaki `VABU-AYARLAR-YÖNETİR` işaretini silersen Vabu Ayarlar o dosyaya bir daha dokunmaz.

## Güvenilirlik ve doğrulama

Çevrimdışı regresyon testleri, yapılan güvenilirlik düzeltmeleri ve Fedora üzerinde doğrulanmayı bekleyen alanlar için [docs/RELIABILITY.md](docs/RELIABILITY.md) dosyasına bak. Firefox RPM olarak gelir; diğer varsayılan Flatpak uygulamaları ilk açılışta internet bağlantısıyla kurulur.

## Masaüstü geliştirmeleri

İlk açılış rehberi, sistem tepsisi, pencere araması (`Super+Tab`), uygulama sağ tık menüsü, adlandırılmış çalışma alanları, isteğe bağlı açılış uygulamaları, ekran profilleri, odak modu ve isteğe bağlı pano geçmişi (`Super+P`) eklendi. Ayarlar'a güç, tanılama/kurtarma, cihazlar, erişilebilirlik ve Türkçe/İngilizce arayüz seçenekleri gelir.

Davranışlar ve gerçek Fedora üzerinde doğrulanmayı bekleyen alanlar [docs/DESKTOP_FEATURES.md](docs/DESKTOP_FEATURES.md) içinde açıklanır. Bu kaynak değişiklikleri gerçek ISO/donanım testinin yerine geçmez. Gelecekteki ISO üretimi için güvenilen anahtar özeti ve imzalı yayın kontrolleri [docs/ISO_TRUST.md](docs/ISO_TRUST.md) içinde anlatılır.

## Lisans

MIT. Ayrıntılar için [LICENSE](LICENSE) dosyasına bak. Yazı tipleri SIL Open Font License ile dağıtılır.

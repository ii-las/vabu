# Vabu

Fedora tabanlı bir Linux dağıtımı. Masaüstü olarak [niri](https://github.com/YaLTeR/niri) ve onun üzerinde çalışan kendi kabuğumuz Vabu Shell geliyor.

Vabu klasik bir Fedora sistemi: `dnf`, RPM dosyaları ve Flathub doğrudan çalışır. Fedora ve RPM Fusion depoları kurulumla birlikte açık gelir.

## Özellikler

- **Vabu Shell** ([Quickshell](https://quickshell.org) ile yazıldı): yan çubuk, uygulama başlatıcı, bildirimler, kilit ekranı, giriş ekranı, ses ve parlaklık göstergeleri
- **Başlatıcıdan uygulama kurma:** `kur:` yazınca Fedora, RPM Fusion ve Flathub'da arar
- **Vabu Ayarlar:** görünüm, ekranlar, ağ, Bluetooth, ses, sürücüler, depolar, güncellemeler, klavye, kullanıcılar
- **Sürücüler:** `vabu-drivers` ekran kartını algılar. NVIDIA (RPM Fusion akmod, Secure Boot destekli), AMD ve Intel için video hızlandırma ve codec'leri kurar.
- **Geri alma noktaları:** her dnf işleminden önce ve sonra btrfs anlık görüntüsü alınır (snapper). Geri dönmek için: `vabu rollback <numara>`.
- **Kurulum:** Calamares, Vabu ekranlarıyla

## Paketler

| Paket | |
|---|---|
| `vabu-release` | os-release ve Vabu deposu (`fedora-release` yerine geçer) |
| `vabu-desktop` | Masaüstü bileşenleri, varsayılan ayarlar, `vabu` ve `vabu-drivers` |
| `vabu-shell` | Vabu Shell, Vabu Ayarlar, giriş ekranı |
| `vabu-fonts` | Instrument Serif, Geist, Geist Mono |
| `quickshell` | Fedora depolarında olmadığı için ayrıca paketleniyor |

Paketler [COPR](https://copr.fedorainfracloud.org/coprs/ii-las/vabu/) üzerinde derleniyor.

## Derleme

Her şey GitHub Actions'ta derleniyor:

- `rpm.yml`: paketleri derler, niri ayarlarını doğrular, COPR'a gönderir
- `quickshell.yml`: Quickshell'i COPR'a gönderir (haftalık olarak da yeniden derler)
- `iso.yml`: Kiwi ile canlı/kurulum ISO'su üretir (x86_64, aarch64)

Bir Fedora makinede yerel olarak derlemek için [docs/BUILDING.md](docs/BUILDING.md) dosyasına bak.

## Dizinler

```
shell/         Vabu Shell, Ayarlar ve giriş ekranı (QML)
shell-system/  vabu-shell paketinin sistem dosyaları
rootfs/        vabu-desktop paketinin dosyaları
branding/      logo ve duvar kağıtları
packaging/     RPM spec dosyaları
iso/           Kiwi ISO tanımı ve Calamares ayarları
```

## niri ayarı

`~/.config/niri/config.kdl` dosyası `/usr/share/vabu/niri/config.kdl.in` şablonundan üretilir. Vabu Ayarlar değişiklikleri `~/.config/vabu/niri.json` dosyasına yazar.

- Üretilen dosya kaydedilmeden önce `niri validate` ile denetlenir.
- Dosyanın sonundaki "Kendi eklemelerin" bölümü korunur.
- İlk satırdaki `VABU-AYARLAR-YÖNETİR` işaretini silersen Vabu Ayarlar o dosyaya bir daha dokunmaz.

## Lisans

MIT. Ayrıntılar için [LICENSE](LICENSE) dosyasına bak. Yazı tipleri SIL Open Font License ile dağıtılır.

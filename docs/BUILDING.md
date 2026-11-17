# Derleme ve deneme

## Paketler

Bir Fedora makinede:

```bash
sudo dnf install rpm-build rpmdevtools librsvg2-tools ImageMagick grub2-tools-extra fonttools jq perl-interpreter just
just rpm
```

Çıktı: `~/rpmbuild/RPMS`

## ISO

Root yetkisi ve `kiwi-cli` gerekir:

```bash
sudo dnf install distribution-gpg-keys kiwi-cli kiwi-systemdeps-iso-media kiwi-systemdeps-bootloaders
COPR_KEY_SHA256=<doğrulanmış-açık-anahtar-dosyası-özeti> just iso
```

ISO `out/` dizinine yazılır. Paketler COPR'dan alındığı için önce COPR derlemelerinin bitmiş olması gerekir.

Temel ISO, Mesa video ve medya için Fedora'nın `mesa-va-drivers` ve
`ffmpeg-free` paketlerini kullanır. RPM Fusion'ın ek codec paketleri Fedora
ile farklı zamanda güncellenebildiği için canlı sistemin zorunlu bağımlılığı
değildir. Ek destek, depolar uyumlu olduğunda Ayarlar → Sürücüler veya
`vabu-drivers install codecs` üzerinden kurulur; imza ve bağımlılık denetimleri korunur.

GitHub'da: Actions → **ISO** → Run workflow. aarch64 ISO, GitHub'ın arm64 makinelerini kullandığı için yalnızca public repoda üretilir.

## Sanal makine

**Linux (QEMU):**

```bash
just vm
```

**macOS (UTM):**
1. Apple Silicon kullanıyorsan aarch64 ISO'yu seç.
2. Create a New Virtual Machine → Virtualize → Linux.
3. "Use Apple Virtualization" seçeneğini kapalı bırak; QEMU, GPU hızlandırması sağlar.
4. ISO'yu seç. 8 GB bellek, 4–6 çekirdek ve 40 GB disk yeterli.
5. VM ayarlarında Display → `virtio-gpu-gl-pci (GPU Supported)` seç.

Canlı oturum açılınca kurulum kendiliğinden başlar.

## Vabu Shell'i kurmadan denemek

Çalışan bir niri oturumunda:

```bash
qs -p shell
```

## Ekran görüntüleri

`tests/ekran.sh` kabuğu başsız bir sway oturumunda çalıştırır, her ekranın görüntüsünü alır ve QML hatalarını denetler. Yalnızca ayrılmış, atılabilir Fedora CI kapsayıcısında:

```bash
dnf install sway grim wtype mesa-dri-drivers dbus-daemon libnotify calamares python3-pyatspi at-spi2-core python3-pyqt6
VABU_TEST_ISOLATED=1 bash tests/ekran.sh /tmp/ekran
```

Hesap formunu tek başına denemek için aynı atılabilir ortamda
`VABU_TEST_ISOLATED=1 bash tests/installer-input.sh /tmp/installer-input`
çalıştırılır. Test `users`, `summary` görünüm modüllerini ve ayrı süreçlerde `welcome`,
`finished` sayfalarını yükler; `exec` dizisi ve disk modülleri içermez. Gerçek
Calamares/AT-SPI üzerinden fare/klavye girişi, parola eşleşmesi, tikler, dil
listesi, Tab/Space ile ilerleme, 1024×768 boyutunda erişilebilirlik ve ileri/geri
geçişte verilerin korunması doğrulanır. Bitiş sayfasında yeniden başlatma seçimi
sınanır; kurulum veya yeniden başlatma çalıştırılmaz. Qt kontrol galerisi
SVG varlıklarının çizimini ve seçim işaretlerini piksel üzerinden denetler.
RPM yayını aarch64 ve x86_64 giriş testleri geçmeden başlamaz.

GitHub Actions bunu her derlemede yapar; görüntüler `ekran` adlı çıktıda durur.

## Duvar kağıtları

`branding/` altındaki duvar kağıtları `tools/duvar-kagidi.py` ile üretilir. Renkleri ya da sırtları değiştirmek için betiği düzenleyip yeniden çalıştır:

```bash
tools/duvar-kagidi.py
```

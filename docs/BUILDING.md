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
sudo dnf install kiwi-cli kiwi-systemdeps-iso-media kiwi-systemdeps-bootloaders
just iso
```

ISO `out/` dizinine yazılır. Paketler COPR'dan alındığı için önce COPR derlemelerinin bitmiş olması gerekir.

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

`tests/ekran.sh` kabuğu başsız bir sway oturumunda çalıştırır, her ekranın görüntüsünü alır ve QML hatalarını denetler. Vabu paketleri kurulu bir Fedora'da:

```bash
sudo dnf install sway grim wtype mesa-dri-drivers dbus-daemon libnotify
tests/ekran.sh /tmp/ekran
```

GitHub Actions bunu her derlemede yapar; görüntüler `ekran` adlı çıktıda durur.

## Duvar kağıtları

`branding/` altındaki duvar kağıtları `tools/duvar-kagidi.py` ile üretilir. Renkleri ya da sırtları değiştirmek için betiği düzenleyip yeniden çalıştır:

```bash
tools/duvar-kagidi.py
```

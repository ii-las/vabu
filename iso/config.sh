#!/bin/bash
# Kiwi: paketler kurulduktan sonra canlı sistemin içinde (chroot) çalışır.
set -euxo pipefail

# Masaüstü ve giriş ekranı
systemctl set-default graphical.target
systemctl enable greetd.service NetworkManager.service

# Canlı kullanıcı: şifresiz, sudo yetkili. Kurulumda Calamares 'removeuser' ile silinir.
useradd -m -G wheel -c "Vabu Canlı" liveuser
passwd -d liveuser
echo 'liveuser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-liveuser
chmod 0440 /etc/sudoers.d/10-liveuser

# Canlı oturum: giriş ekranını atlayıp doğrudan masaüstü, kurulum aracı otomatik açılır.
cat >> /etc/greetd/vabu.toml <<'TOML'

[initial_session]
command = "niri-session"
user = "liveuser"
TOML

install -d -o liveuser -g liveuser /home/liveuser/.config /home/liveuser/.config/niri
cp /etc/niri/config.kdl /home/liveuser/.config/niri/config.kdl
cat >> /home/liveuser/.config/niri/config.kdl <<'KDL'

// Canlı oturum: Vabu kurulumunu başlat.
spawn-at-startup "sh" "-c" "sudo -E calamares"
KDL
chown liveuser:liveuser /home/liveuser/.config/niri/config.kdl

# Flathub kurulum sonrası ilk açılışta eklenir (vabu-flatpak-setup); canlıda gerek yok.
systemctl disable vabu-flatpak-setup.service vabu-update.timer vabu-snapper-setup.service || true

# Calamares QML modülleri (welcomeq, usersq, summaryq, finishedq) bu Calamares
# derlemesinde yoksa klasik karşılıklarını kullan; kurulum her durumda açılsın.
for m in welcomeq usersq summaryq finishedq; do
    if ! ls -d /usr/lib*/calamares/modules/"$m" >/dev/null 2>&1; then
        echo "UYARI: Calamares '$m' modülü yok, '${m%q}' kullanılacak."
        sed -i "s/- ${m}\$/- ${m%q}/" /etc/calamares/settings.conf
    fi
done

# aarch64: sb-shim yalnızca x86_64 shim dosyalarını tanır; orada düz grub kullanılır.
if [ "$(uname -m)" = "aarch64" ]; then
    sed -i 's/^efiBootLoader: .*/efiBootLoader: "grub"/' /etc/calamares/modules/bootloader.conf
fi

# Başlatıcıda Calamares'in kendi girişi yerine "Vabu'yu kur" görünsün
if [ -f /usr/share/applications/calamares.desktop ]; then echo 'NoDisplay=true' >> /usr/share/applications/calamares.desktop; fi

# Fedora'nın waybar ve mako servisleri Vabu Shell ile çakışmasın
systemctl --global mask waybar.service mako.service || true

# Yerel ayar
echo 'LANG=tr_TR.UTF-8' > /etc/locale.conf

#!/bin/bash
# Kiwi: paketler kurulduktan sonra canlı sistemin içinde (chroot) çalışır.
set -euxo pipefail

# Masaüstü ve giriş ekranı
systemctl set-default graphical.target
systemctl enable greetd.service NetworkManager.service

# Canlı kullanıcı: şifresiz, sudo yetkili. Kurulum bu kullanıcıyla açılır;
# yalnızca arka ucu root olarak (sudo -n) çalışır.
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
# Canlı oturumda kurulum kendiliğinden, tam ekran açılsın. Satırlar "kendi eklemelerin"
# bölümüne yazılır; Vabu Ayarlar dosyayı yeniden üretirken (klavye seçilince de) o bölümü korur.
canli='// Canlı oturum: Vabu kurulumu açılışta tam ekran gelsin.
spawn-at-startup "vabu-installer"
window-rule {
    match app-id=r#"^org\.quickshell$"# title="^Vabu'"'"'yu kur$"
    open-fullscreen true
}'
kdl=/home/liveuser/.config/niri/config.kdl
if grep -q '^// VABU-KULLANICI-SON' "$kdl"; then
    { sed '/^\/\/ VABU-KULLANICI-SON/,$d' "$kdl"; printf '%s\n' "$canli"; sed -n '/^\/\/ VABU-KULLANICI-SON/,$p' "$kdl"; } > "$kdl.yeni"
    mv "$kdl.yeni" "$kdl"
else
    printf '\n%s\n' "$canli" >> "$kdl"
fi
# Yan panelde ilk sırada "Vabu'yu kur": kurulum kapatılsa da bir tıkla yeniden açılır
install -d -o liveuser -g liveuser /home/liveuser/.config/vabu
cat > /home/liveuser/.config/vabu/shell.json <<'JSON'
{
  "pinned": ["vabu-kur", "org.mozilla.firefox", "foot", "org.gnome.Nautilus", "so.vabu.Settings", "org.gnome.TextEditor"]
}
JSON
chown -R liveuser:liveuser /home/liveuser/.config/niri /home/liveuser/.config/vabu

# Flathub kurulum sonrası ilk açılışta eklenir (vabu-flatpak-setup); canlıda gerek yok.
systemctl disable vabu-flatpak-setup.service vabu-update.timer vabu-snapper-setup.service || true

# Fedora'nın waybar ve mako servisleri Vabu Shell ile çakışmasın
systemctl --global mask waybar.service mako.service || true

# Yerel ayar
echo 'LANG=tr_TR.UTF-8' > /etc/locale.conf

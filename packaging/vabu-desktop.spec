# Vabu masaüstü: varsayılan ayarlar, araçlar, tema ve tüm masaüstünü çeken meta paket.
# Kaynak: repo kökünden üretilen vabu-<sürüm>.tar.gz (rootfs/, branding/).

# CI injects the source commit; local builds explicitly identify as unknown.
%{!?vabu_source_commit:%global vabu_source_commit unknown}

Name:           vabu-desktop
Version:        0.1.0
Release:        1%{?dist}
Summary:        Vabu masaüstü ortamı ve sistem araçları
License:        MIT
URL:            https://github.com/ii-las/vabu
Source0:        vabu-%{version}.tar.gz
# Önyükleme menüsünün yazı tipi bundan üretilir (vabu-fonts ile aynı dosya)
Source1:        https://github.com/google/fonts/raw/main/ofl/hankengrotesk/HankenGrotesk%5Bwght%5D.ttf#/HankenGrotesk-Variable.ttf
BuildArch:      noarch
Provides:       vabu-source-commit = %{vabu_source_commit}

BuildRequires:  librsvg2-tools
BuildRequires:  ImageMagick
BuildRequires:  grub2-tools-extra
BuildRequires:  fonttools
BuildRequires:  fontconfig
BuildRequires:  jetbrains-mono-fonts
BuildRequires:  python3
BuildRequires:  jq
BuildRequires:  perl-interpreter
BuildRequires:  systemd-rpm-macros

Requires:       vabu-release = %{version}-%{release}

# Masaüstü çekirdeği
Requires:       niri
Requires:       xwayland-satellite
Requires:       xdg-desktop-portal-gnome
Requires:       xdg-desktop-portal-gtk
Requires:       gnome-keyring
Requires:       lxqt-policykit
Requires:       network-manager-applet
Requires:       nm-connection-editor
Requires:       pavucontrol
Requires:       pipewire
Requires:       wireplumber
Requires:       brightnessctl
Requires:       playerctl
Requires:       grim
Requires:       slurp
Requires:       wl-clipboard
Requires:       switcheroo-control
# Giriş ekranı (Vabu greeter, Vabu Shell ile birlikte gelir)
Requires:       greetd
Requires:       tuigreet
Requires:       swayidle
# Vabu Shell açılamazsa kilit için yedek
Requires:       swaylock
# Uygulamalar
Requires:       foot
Requires:       nautilus
Requires:       firefox
Requires:       flatpak
Requires:       fastfetch
# Geri alma noktaları
Requires:       snapper
Requires:       btrfs-progs
Requires:       cryptsetup
Requires:       util-linux
Requires:       libdnf5-plugin-actions
Requires:       dnf5
Requires:       dnf5-plugins
# Sürücü aracı
Requires:       pciutils
Requires:       mokutil
Requires:       jq
Requires:       perl-interpreter
Requires:       fuzzel
Requires:       waybar
Requires:       mako
Requires:       blueman
Requires:       cups
Requires:       system-config-printer
Requires:       simple-scan
Requires:       gnome-disk-utility
Requires:       gvfs-mtp
Requires:       gvfs-smb
Requires:       NetworkManager-openvpn-gnome
Requires:       NetworkManager-openconnect-gnome
Requires:       swaybg
# Başlatıcıda uygulama kurma: AppStream kataloglarından yerel dizin
Requires:       gtk3
Requires:       python3
Requires:       appstream-data
Recommends:     rpmfusion-free-appstream-data
Recommends:     rpmfusion-nonfree-appstream-data
# Oyun
Requires:       gamescope
Requires:       gamemode
Requires:       mangohud
# Görünüm
Requires:       adw-gtk3-theme
Requires:       papirus-icon-theme
Requires:       rsms-inter-fonts
Requires:       jetbrains-mono-fonts-all
Requires:       plymouth-plugin-script

Requires:       vabu-shell = %{version}-%{release}

%description
Vabu'yu Vabu yapan her şey: niri yapılandırması, vabu ve vabu-drivers araçları,
güncelleme ve geri alma noktası servisleri, açılış ekranı, duvar kağıdı ve
masaüstünü oluşturan paketler.

%prep
%autosetup -n vabu-%{version}

%build
# Duvar kağıtları: gren yüzünden PNG çok büyür, JPEG olarak paketlenir
for n in wallpaper wallpaper-gece wallpaper-gunduz; do
    rsvg-convert -w 3840 -h 2160 branding/$n.svg -o $n.png
    magick $n.png -quality 92 -sampling-factor 4:4:4 -interlace none $n.jpg
done
rsvg-convert -w 256  -h 256  branding/logo.svg      -o logo-256.png

# Açılış ekranı (Plymouth): zeminsiz işaret ve ilerleme çizgisi parçaları
rsvg-convert -w 512 -h 512 branding/logo-mark.svg -o plymouth-logo.png
magick -size 8x8 xc:'#EFECE6' fill.png
magick -size 8x8 xc:'rgba(255,255,255,0.16)' track.png

# Önyükleme menüsü (GRUB) teması
mkdir -p grub
magick -size 1920x1080 xc:'#202420' -depth 8 grub/background.png
rsvg-convert -w 104 -h 104 branding/logo-mark.svg -o grub/logo.png
# seçili satırın zemini: yuvarlak köşeli hap, dokuz parçaya bölünür. Köşe parçaları
# satırın üstüne ve altına taşar; tema satır yüksekliğini buna göre ayarlar (30 + 2 × 12).
# GRUB yalnızca 8 bit RGBA PNG okur; PNG32: biçimi paletli yazılmasını önler.
magick -size 36x36 xc:none -fill '#8FB2FF' -draw 'roundrectangle 0,0 35,35 12,12' PNG32:pill.png
i=0
for part in nw n ne w c e sw s se; do
    magick pill.png -crop "12x12+$(( (i % 3) * 12 ))+$(( (i / 3) * 12 ))" +repage PNG32:grub/select_$part.png
    i=$(( i + 1 ))
done
fonttools varLib.instancer -q -o HG-Medium.ttf %{SOURCE1} wght=500
fonttools varLib.instancer -q -o HG-Regular.ttf %{SOURCE1} wght=400
grub2-mkfont -n Vabu -s 22 -o grub/vabu-22.pf2 HG-Medium.ttf
grub2-mkfont -n Vabu -s 15 -o grub/vabu-15.pf2 HG-Regular.ttf
# komut satırı eşit aralıklı yazı ister
jbm="$(fc-match -f '%%{file}' 'JetBrains Mono:style=Regular')"
fonttools varLib.instancer -q -o JBM.ttf "$jbm" wght=400 || cp "$jbm" JBM.ttf
grub2-mkfont -n "Vabu Mono" -s 16 -o grub/vabu-mono-16.pf2 JBM.ttf
# komut satırının zemini: koyu, yuvarlak köşeli kutu (dokuz parça)
magick -size 48x48 xc:none -fill 'rgba(23,21,26,0.94)' -draw 'roundrectangle 0,0 47,47 16,16' PNG32:box.png
i=0
for part in nw n ne w c e sw s se; do
    magick box.png -crop "16x16+$(( (i % 3) * 16 ))+$(( (i / 3) * 16 ))" +repage PNG32:grub/terminal_box_$part.png
    i=$(( i + 1 ))
done
# temada geçen yazı tipi adı .pf2 içindeki adla birebir aynı olmalı
pf2name() { python3 -c 'import sys, struct; d = open(sys.argv[1], "rb").read(); i = d.index(b"NAME"); n = struct.unpack(">I", d[i + 4:i + 8])[0]; print(d[i + 8:i + 8 + n].rstrip(b"\0").decode())' "$1"; }
sed -e "s/@FONT_L@/$(pf2name grub/vabu-22.pf2)/" -e "s/@FONT_S@/$(pf2name grub/vabu-15.pf2)/" \
    -e "s/@FONT_MONO@/$(pf2name grub/vabu-mono-16.pf2)/" \
    branding/grub/theme.txt.in > grub/theme.txt
grep -n font grub/theme.txt
# niri varsayılan ayarı şablondan (Vabu Ayarlar da aynı üreticiyi kullanır)
VABU_NIRI_TEMPLATE=rootfs/usr/share/vabu/niri/config.kdl.in \
    bash rootfs/usr/libexec/vabu/niri-config --defaults -o niri-default.kdl

%install
cp -a rootfs/. %{buildroot}/
for n in wallpaper wallpaper-gece wallpaper-gunduz; do
    install -Dm0644 $n.jpg %{buildroot}%{_datadir}/vabu/assets/$n.jpg
done
install -Dm0644 plymouth-logo.png %{buildroot}%{_datadir}/plymouth/themes/vabu/logo.png
install -m0644 fill.png track.png %{buildroot}%{_datadir}/plymouth/themes/vabu/
# GRUB teması: açılışta okunabilmesi için /boot altında; ISO üreticisi (kiwi) /usr/share'den alır
for dir in /boot/grub2/themes/vabu %{_datadir}/grub/themes/vabu; do
    install -d %{buildroot}$dir
    install -m0644 grub/* %{buildroot}$dir/
done
install -Dm0644 logo-256.png   %{buildroot}%{_datadir}/pixmaps/vabu-logo.png
install -Dm0644 branding/logo.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/vabu-logo.svg
install -Dm0644 niri-default.kdl %{buildroot}%{_sysconfdir}/niri/config.kdl
install -Dm0644 niri-default.kdl %{buildroot}%{_datadir}/vabu/niri/config.kdl

%post
%systemd_post vabu-update.timer vabu-snapper-setup.service vabu-flatpak-setup.service
%systemd_user_post vabu-user-update.timer vabu-idle.service
if [ $1 -eq 1 ]; then
    systemctl enable greetd.service >/dev/null 2>&1 || :
    systemctl set-default graphical.target >/dev/null 2>&1 || :
    systemctl enable vabu-update.timer vabu-snapper-setup.service vabu-flatpak-setup.service >/dev/null 2>&1 || :
    systemctl --global enable vabu-user-update.timer >/dev/null 2>&1 || :
    plymouth-set-default-theme vabu >/dev/null 2>&1 || :
fi
# niri'nin önerdiği waybar ve mako kurulu olabilir; kendiliğinden başlayıp Vabu Shell'in
# barıyla ve bildirim sunucusuyla çakışmasınlar
systemctl --global mask waybar.service mako.service >/dev/null 2>&1 || :
glib-compile-schemas %{_datadir}/glib-2.0/schemas >/dev/null 2>&1 || :

%preun
%systemd_preun vabu-update.timer vabu-snapper-setup.service vabu-flatpak-setup.service
%systemd_user_preun vabu-user-update.timer vabu-idle.service

%postun
glib-compile-schemas %{_datadir}/glib-2.0/schemas >/dev/null 2>&1 || :

%files
%license LICENSE
%config(noreplace) %{_sysconfdir}/niri/config.kdl
%config(noreplace) %{_sysconfdir}/greetd/vabu.toml
%config(noreplace) %{_sysconfdir}/dnf/libdnf5-plugins/actions.d/vabu-snapper.actions
%config(noreplace) %{_sysconfdir}/nvidia/nvidia-application-profiles-rc.d/50-vabu-niri.json
%{_bindir}/vabu
%{_bindir}/vabu-drivers
%{_bindir}/vabu-launcher
%{_bindir}/vabu-power-menu
%{_libexecdir}/vabu/
%{_unitdir}/vabu-update.service
%{_unitdir}/vabu-update.timer
%{_unitdir}/vabu-snapper-setup.service
%{_unitdir}/vabu-flatpak-setup.service
%{_unitdir}/greetd.service.d/vabu.conf
%{_userunitdir}/vabu-idle.service
%{_userunitdir}/vabu-user-update.service
%{_userunitdir}/vabu-user-update.timer
%{_datadir}/vabu/
%{_datadir}/glib-2.0/schemas/zz0-vabu.gschema.override
%{_datadir}/plymouth/themes/vabu/
/boot/grub2/themes/vabu/
%{_datadir}/grub/themes/vabu/
%{_datadir}/pixmaps/vabu-logo.png
%{_datadir}/icons/hicolor/scalable/apps/vabu-logo.svg
%{_datadir}/wayland-sessions/vabu-gaming.desktop
%{_datadir}/wayland-sessions/vabu-recovery.desktop

%changelog
* Sun Nov 15 2026 ii-las <ii-las@users.noreply.github.com> - 0.1.0-1
- İlk sürüm

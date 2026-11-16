# Vabu masaüstü: varsayılan ayarlar, araçlar, tema ve tüm masaüstünü çeken meta paket.
# Kaynak: repo kökünden üretilen vabu-<sürüm>.tar.gz (rootfs/, branding/).

Name:           vabu-desktop
Version:        0.1.0
Release:        1%{?dist}
Summary:        Vabu masaüstü ortamı ve sistem araçları
License:        MIT
URL:            https://github.com/ii-las/vabu
Source0:        vabu-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  librsvg2-tools
BuildRequires:  ImageMagick
BuildRequires:  jq
BuildRequires:  perl-interpreter
BuildRequires:  systemd-rpm-macros

Requires:       vabu-release

# Masaüstü çekirdeği
Requires:       niri
Requires:       xwayland-satellite
Requires:       xdg-desktop-portal-gnome
Requires:       xdg-desktop-portal-gtk
Requires:       gnome-keyring
Requires:       lxqt-policykit
Requires:       network-manager-applet
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
Requires:       flatpak
Requires:       fastfetch
# Geri alma noktaları
Requires:       snapper
Requires:       libdnf5-plugin-actions
# Sürücü aracı
Requires:       pciutils
Requires:       mokutil
Requires:       jq
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

Requires:       vabu-shell

%description
Vabu'yu Vabu yapan her şey: niri yapılandırması, vabu ve vabu-drivers araçları,
güncelleme ve geri alma noktası servisleri, açılış ekranı, duvar kağıdı ve
masaüstünü oluşturan paketler.

%prep
%autosetup -n vabu-%{version}

%build
# Duvar kağıtları: gren yüzünden PNG çok büyür, JPEG olarak paketlenir
for n in wallpaper wallpaper-gece wallpaper-sis; do
    rsvg-convert -w 3840 -h 2160 branding/$n.svg -o $n.png
    magick $n.png -quality 92 -sampling-factor 4:4:4 -interlace none $n.jpg
done
rsvg-convert -w 256  -h 256  branding/logo.svg      -o logo-256.png
rsvg-convert -w 128  -h 128  branding/logo.svg      -o logo-128.png
# niri varsayılan ayarı şablondan (Vabu Ayarlar da aynı üreticiyi kullanır)
VABU_NIRI_TEMPLATE=rootfs/usr/share/vabu/niri/config.kdl.in \
    bash rootfs/usr/libexec/vabu/niri-config --defaults -o niri-default.kdl

%install
cp -a rootfs/. %{buildroot}/
for n in wallpaper wallpaper-gece wallpaper-sis; do
    install -Dm0644 $n.jpg %{buildroot}%{_datadir}/vabu/assets/$n.jpg
done
install -Dm0644 logo-128.png   %{buildroot}%{_datadir}/plymouth/themes/vabu/logo.png
install -Dm0644 logo-256.png   %{buildroot}%{_datadir}/pixmaps/vabu-logo.png
install -Dm0644 branding/logo.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/vabu-logo.svg
install -Dm0644 niri-default.kdl %{buildroot}%{_sysconfdir}/niri/config.kdl
install -Dm0644 niri-default.kdl %{buildroot}%{_datadir}/vabu/niri/config.kdl

%post
%systemd_post vabu-update.timer vabu-snapper-setup.service vabu-flatpak-setup.service
%systemd_user_post vabu-user-update.timer
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
%systemd_user_preun vabu-user-update.timer

%postun
glib-compile-schemas %{_datadir}/glib-2.0/schemas >/dev/null 2>&1 || :

%files
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
%{_userunitdir}/vabu-user-update.service
%{_userunitdir}/vabu-user-update.timer
%{_datadir}/vabu/
%{_datadir}/glib-2.0/schemas/zz0-vabu.gschema.override
%{_datadir}/plymouth/themes/vabu/
%{_datadir}/pixmaps/vabu-logo.png
%{_datadir}/icons/hicolor/scalable/apps/vabu-logo.svg
%{_datadir}/wayland-sessions/vabu-gaming.desktop

%changelog
* Sun Nov 15 2026 ii-las <ii-las@users.noreply.github.com> - 0.1.0-1
- İlk sürüm

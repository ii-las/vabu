# Vabu Shell: yan çubuk, başlatıcı, bildirimler, kilit ve giriş ekranı, göstergeler + Vabu Ayarlar ve kurulum.
# Kaynak: repo kökündeki shell/ (QML) ve shell-system/ (sistem dosyaları).

Name:           vabu-shell
Version:        0.1.0
Release:        1%{?dist}
Summary:        Vabu masaüstü kabuğu
License:        MIT
URL:            https://github.com/ii-las/vabu
Source0:        vabu-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  systemd-rpm-macros

Requires:       quickshell
Requires:       vabu-fonts
Requires:       niri
Requires:       swayidle
Requires:       brightnessctl
Requires:       wlsunset
Requires:       NetworkManager
Requires:       wl-clipboard
Requires:       libnotify
Requires:       polkit
Requires:       greetd
Requires:       papirus-icon-theme
# Vabu Ayarlar'ın kullandığı araçlar
Requires:       bluez
Requires:       glib2
Requires:       xdg-utils
Requires:       util-linux
Requires:       pciutils
Requires:       snapper
Requires:       jq
# Vabu kurulumu: saat dilimi listesi, arka uç sudo ile çalışır
Requires:       tzdata
Requires:       sudo
Recommends:     pavucontrol
Recommends:     nm-connection-editor

%description
Vabu'nun kendi masaüstü kabuğu (Quickshell/QML): buzlu cam yan panel (saat, çalışma
alanları, uygulamalar, medya, durum), yan panelden açılan Wi-Fi, Bluetooth, ses, takvim,
bildirim ve kontrol merkezi panelleri; ara/kur/komut kipli başlatıcı; kilit ve giriş
ekranı; ses/parlaklık göstergesi, kısayollar ve oturum menüsü; canlı ortamdaki Vabu kurulumu.

%prep
%autosetup -n vabu-%{version}

%build

%install
install -d %{buildroot}%{_datadir}/vabu/shell
cp -a shell/*.qml %{buildroot}%{_datadir}/vabu/shell/
cp -a shell-system/. %{buildroot}/

%post
%tmpfiles_create vabu-greeter.conf

%files
%{_datadir}/vabu/shell/
%{_datadir}/vabu/greeter/
%{_bindir}/vabu-brightness
%{_bindir}/vabu-settings
%{_bindir}/vabu-installer
%{_datadir}/applications/so.vabu.Settings.desktop
%config(noreplace) %{_sysconfdir}/pam.d/vabu-lock
%{_tmpfilesdir}/vabu-greeter.conf

%changelog
* Sun Nov 15 2026 ii-las <ii-las@users.noreply.github.com> - 0.1.0-1
- İlk sürüm

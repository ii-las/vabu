# Quickshell - Vabu Shell'in üzerinde çalıştığı QML kabuk araç takımı.
# Fedora resmi depolarında yok; Vabu COPR'ında biz derliyoruz.
# ÖNEMLİ: Quickshell Qt'nin özel (private) API'lerini kullanır. Fedora Qt'yi
# güncellediğinde bu paket de yeniden derlenmeli (COPR'da "Rebuild"). Aksi halde kabuk açılmaz.

Name:           quickshell
Version:        0.2.1
Release:        1%{?dist}
Summary:        QML ile masaüstü kabukları yazmak için araç takımı
License:        LGPL-3.0-only AND GPL-3.0-only
URL:            https://quickshell.org
Source0:        https://github.com/quickshell-mirror/quickshell/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  ninja-build
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig
BuildRequires:  spirv-tools
BuildRequires:  cli11-devel
BuildRequires:  jemalloc-devel
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtbase-private-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  qt6-qtshadertools-devel
BuildRequires:  qt6-qtwayland-devel
BuildRequires:  wayland-devel
BuildRequires:  wayland-protocols-devel
BuildRequires:  libdrm-devel
BuildRequires:  mesa-libgbm-devel
BuildRequires:  pipewire-devel
BuildRequires:  pam-devel
BuildRequires:  polkit-devel
BuildRequires:  glib2-devel
BuildRequires:  libxcb-devel

Requires:       qt6-qtdeclarative
Requires:       qt6-qtwayland
Requires:       qt6-qtsvg
Requires:       qt6-qt5compat

%description
Quickshell, QtQuick ile Wayland masaüstü kabukları (bar, başlatıcı, kilit ekranı,
bildirim sunucusu, greeter) yazmayı sağlayan bir araç takımıdır.

%prep
%autosetup -n quickshell-%{version}

%build
%cmake -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DDISTRIBUTOR="Vabu (COPR)" \
    -DDISTRIBUTOR_DEBUGINFO_AVAILABLE=YES \
    -DCRASH_REPORTER=OFF \
    -DINSTALL_QML_PREFIX=%{_lib}/qt6/qml
%cmake_build

%install
%cmake_install

%files
%license LICENSE*
%doc README.md
%{_bindir}/*
%{_libdir}/qt6/qml/Quickshell/
# Masaüstü dosyası ve simge sürümden sürüme değişebildiği için geniş tutuldu
%{_datadir}/*

%changelog
* Sun Nov 15 2026 ii-las <ii-las@users.noreply.github.com> - 0.2.1-1
- Vabu için ilk paket

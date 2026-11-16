# Vabu arayüz yazı tipleri ve ikon fontu.
#   Hanken Grotesk         arayüz yazısı (OFL)
#   Material Symbols Rounded  ikonlar, değişken: dolgu/kalınlık animasyonu (Apache-2.0)
#   JetBrains Mono: terminal (Fedora paketi, bağımlılık olarak gelir)
%global gf https://github.com/google/fonts/raw/main/ofl
%global ms https://github.com/google/material-design-icons/raw/master

Name:           vabu-fonts
Version:        2.1
Release:        1%{?dist}
Summary:        Vabu arayüz yazı tipleri ve ikon fontu
License:        OFL-1.1 AND Apache-2.0
URL:            https://github.com/ii-las/vabu
BuildArch:      noarch
Source0:        %{gf}/hankengrotesk/HankenGrotesk%5Bwght%5D.ttf#/HankenGrotesk-Variable.ttf
Source1:        %{gf}/hankengrotesk/HankenGrotesk-Italic%5Bwght%5D.ttf#/HankenGrotesk-Italic-Variable.ttf
Source2:        %{gf}/hankengrotesk/OFL.txt#/OFL-HankenGrotesk.txt
Source3:        %{ms}/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf#/MaterialSymbolsRounded-Variable.ttf
Source4:        %{ms}/LICENSE#/LICENSE-MaterialSymbols.txt

Requires:       fontconfig
Requires:       jetbrains-mono-fonts

%description
Vabu Shell, Vabu Ayarlar, kurulum ve önyükleme ekranının kullandığı yazı tipleri.

%prep
%build

%install
install -d %{buildroot}%{_datadir}/fonts/vabu
install -m0644 %{SOURCE0} %{SOURCE1} %{SOURCE3} %{buildroot}%{_datadir}/fonts/vabu/
install -d %{buildroot}%{_datadir}/licenses/%{name}
install -m0644 %{SOURCE2} %{SOURCE4} %{buildroot}%{_datadir}/licenses/%{name}/

%files
%{_datadir}/fonts/vabu/
%{_datadir}/licenses/%{name}/

%changelog
* Mon Nov 16 2026 ii-las <ii-las@users.noreply.github.com> - 2.1-1
- Newsreader çıkarıldı; arayüz yalnızca Hanken Grotesk kullanıyor

* Mon Nov 16 2026 ii-las <ii-las@users.noreply.github.com> - 2.0-1
- Newsreader, Hanken Grotesk ve Material Symbols Rounded

* Sun Nov 15 2026 ii-las <ii-las@users.noreply.github.com> - 1.0-1
- İlk paket

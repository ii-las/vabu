# Vabu yazı tipleri: Instrument Serif (başlık), Geist (arayüz), Geist Mono (etiket).
# Hepsi SIL Open Font License; Fedora depolarında yoklar.
%global gf https://github.com/google/fonts/raw/main/ofl

Name:           vabu-fonts
Version:        1.0
Release:        1%{?dist}
Summary:        Vabu arayüz yazı tipleri
License:        OFL-1.1
URL:            https://github.com/google/fonts
BuildArch:      noarch
Source0:        %{gf}/instrumentserif/InstrumentSerif-Regular.ttf
Source1:        %{gf}/instrumentserif/InstrumentSerif-Italic.ttf
Source2:        %{gf}/instrumentserif/OFL.txt#/OFL-InstrumentSerif.txt
Source3:        %{gf}/geist/Geist%5Bwght%5D.ttf#/Geist-Variable.ttf
Source4:        %{gf}/geist/OFL.txt#/OFL-Geist.txt
Source5:        %{gf}/geistmono/GeistMono%5Bwght%5D.ttf#/GeistMono-Variable.ttf
Source6:        %{gf}/geistmono/OFL.txt#/OFL-GeistMono.txt

Requires:       fontconfig

%description
Vabu Shell, Vabu Ayarlar ve Vabu Kurulum'un kullandığı yazı tipleri.

%prep
%build

%install
install -d %{buildroot}%{_datadir}/fonts/vabu
install -m0644 %{SOURCE0} %{SOURCE1} %{SOURCE3} %{SOURCE5} %{buildroot}%{_datadir}/fonts/vabu/
install -d %{buildroot}%{_datadir}/licenses/%{name}
install -m0644 %{SOURCE2} %{SOURCE4} %{SOURCE6} %{buildroot}%{_datadir}/licenses/%{name}/

%files
%{_datadir}/fonts/vabu/
%{_datadir}/licenses/%{name}/

%changelog
* Sun Nov 15 2026 ii-las <ii-las@users.noreply.github.com> - 1.0-1
- İlk paket

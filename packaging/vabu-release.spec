# Vabu kimliği: os-release, depo tanımları. Fedora'nın "remix" kuralına göre
# fedora-release yerine geçer (generic-release ile aynı yaklaşım).
%global fedora_ver %{fedora}
# COPR_OWNER dosyasındaki kullanıcı adı CI'da buraya yazılır
%global copr_owner ii-las

Name:           vabu-release
Version:        0.1.0
Release:        1%{?dist}
Summary:        Vabu sürüm ve depo dosyaları
License:        MIT
URL:            https://github.com/ii-las/vabu
BuildArch:      noarch

Provides:       system-release
Provides:       system-release(%{fedora_ver})
# dnf $releasever'ı buradan okur; yoksa paket sürümünü (0.1.0) kullanır ve depolar bozulur
Provides:       system-release(releasever) = %{fedora_ver}
Provides:       base-module(platform:f%{fedora_ver})
Conflicts:      fedora-release
Conflicts:      fedora-release-common
Conflicts:      generic-release
Requires:       fedora-repos(%{fedora_ver})

%description
Vabu'yu tanımlayan dosyalar: /usr/lib/os-release, Vabu COPR deposu ve
sistem sürümü bilgisi. Vabu, Fedora tabanlı bir remix'tir.

%install
install -d %{buildroot}%{_prefix}/lib %{buildroot}%{_sysconfdir}/yum.repos.d
cat > %{buildroot}%{_prefix}/lib/os-release <<OSR
NAME="Vabu"
VERSION="%{version} (Fedora %{fedora_ver} tabanlı)"
ID=vabu
ID_LIKE=fedora
VERSION_ID=%{fedora_ver}
PLATFORM_ID="platform:f%{fedora_ver}"
PRETTY_NAME="Vabu %{version}"
ANSI_COLOR="0;38;2;142;240;198"
LOGO=vabu-logo
CPE_NAME="cpe:/o:vabu:vabu:%{fedora_ver}"
DEFAULT_HOSTNAME="vabu"
HOME_URL="https://github.com/ii-las/vabu"
SUPPORT_URL="https://github.com/ii-las/vabu/discussions"
BUG_REPORT_URL="https://github.com/ii-las/vabu/issues"
VARIANT="Vabu"
VARIANT_ID=vabu
OSR
ln -s ../usr/lib/os-release %{buildroot}%{_sysconfdir}/os-release
echo "Vabu release %{version} (Fedora %{fedora_ver})" > %{buildroot}%{_sysconfdir}/vabu-release
ln -s vabu-release %{buildroot}%{_sysconfdir}/system-release
ln -s vabu-release %{buildroot}%{_sysconfdir}/redhat-release
echo "cpe:/o:vabu:vabu:%{fedora_ver}" > %{buildroot}%{_sysconfdir}/system-release-cpe

cat > %{buildroot}%{_sysconfdir}/yum.repos.d/vabu.repo <<REPO
[vabu]
name=Vabu – Fedora \$releasever
baseurl=https://download.copr.fedorainfracloud.org/results/%{copr_owner}/vabu/fedora-\$releasever-\$basearch/
type=rpm-md
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/%{copr_owner}/vabu/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
REPO

%files
%{_prefix}/lib/os-release
%{_sysconfdir}/os-release
%{_sysconfdir}/vabu-release
%{_sysconfdir}/system-release
%{_sysconfdir}/redhat-release
%{_sysconfdir}/system-release-cpe
%config(noreplace) %{_sysconfdir}/yum.repos.d/vabu.repo

%changelog
* Sun Nov 15 2026 ii-las <ii-las@users.noreply.github.com> - 0.1.0-1
- İlk sürüm

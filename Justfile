# Vabu yerel komutları - bir Fedora makinede çalıştır.

version := `cat VERSION`
fedora  := `cat FEDORA_VERSION`
owner   := `cat COPR_OWNER`
arch    := `uname -m`

# RPM paketlerini derle (~/rpmbuild)
rpm:
    rpmdev-setuptree
    git archive --format=tar.gz --prefix="vabu-{{version}}/" -o ~/rpmbuild/SOURCES/vabu-{{version}}.tar.gz HEAD rootfs branding shell shell-system
    for spec in packaging/*.spec; do spectool -g -R "$spec"; sudo dnf -y builddep "$spec"; rpmbuild -ba "$spec"; done

# Vabu Shell'i kurmadan, çalışan bir niri oturumunda dene
shell:
    qs -p shell

# Canlı/kurulum ISO'su üret (root ister, kiwi-cli gerekir)
iso:
    rm -rf out && mkdir -p out/desc && cp -a iso/. out/desc/
    sed -i "s/@FEDORA@/{{fedora}}/g; s/@ARCH@/{{arch}}/g; s#/vabu-os/#/{{owner}}/#g" out/desc/config.kiwi
    sudo kiwi-ng system build --description out/desc --target-dir out

# Üretilen ISO'yu sanal makinede dene
vm:
    qemu-system-{{arch}} -enable-kvm -m 8G -smp 4 -cpu host \
        -bios /usr/share/edk2/ovmf/OVMF_CODE.fd \
        -cdrom out/*.iso -device virtio-vga-gl -display gtk,gl=on

#!/usr/bin/env bash
# Kurulum arka ucunu (install-system) baştan sona dener:
#  1. hızlı denetimler: --disks, --dry-run ve hatalı girdiler (kök kurulmadan)
#  2. iso/config.kiwi'deki paketlerle canlı imaja benzeyen bir kök kurulur (dnf --installroot);
#     Kiwi'deki gibi iso/root kopyalanır ve iso/config.sh çalıştırılır
#  3. kökün üstüne canlı oturumdaki gibi bir overlay kurulur, alt katman /run/rootfsbase'de
#  4. install-system bu ortamda liveuser'ın sudo'suyla sanal bir diske (loop) kurar,
#     kurulan sistem diskten okunup denetlenir
#  5. disk QEMU'da açılır: giriş ekranı gelmeli, kullanıcı parolasıyla (ya da kendiliğinden)
#     oturum açabilmeli. Seri kayıt ve ekran görüntüleri çıktı klasörüne yazılır.
#
#   tests/kurulum.sh <çalışma klasörü> <çıktı klasörü> [deneme ...]
#   denemeler: uefi uefi-sifreli bios (varsayılan: hepsi)
#
# Fedora container'ında root olarak, --privileged ve -v /dev:/dev ile çalışır (bkz. rpm.yml).
set -euo pipefail

W=$(realpath -m "$1") OUT=$(realpath -m "$2")
shift 2
if (( $# )); then DENEMELER=("$@"); else DENEMELER=(uefi uefi-sifreli bios); fi
REPO=$(cd "$(dirname "$0")/.." && pwd)
FEDORA=$(cat "$REPO/FEDORA_VERSION")
ARCH=$(uname -m)
BETIK=$REPO/rootfs/usr/libexec/vabu/install-system
KOK=$W/kok          # canlı imajın kökü (Kiwi'nin ürettiği erofs'un içeriği)
CANLI=$W/canli      # canlı oturumun kökü: KOK + yazılabilir üst katman
PAROLA=vabu1234
DISK_PAROLASI=vabuparola2026
# Seri konsola systemd durumu ve günlük düşsün; giriş ekranı ve oturum buradan izlenir
EK_SATIR="console=tty0 console=ttyS0,115200 systemd.show_status=1 systemd.journald.forward_to_console=1"
SURUCULER="virtio_blk virtio_pci"
mkdir -p "$W" "$OUT"

HATALAR=()
basarisiz() { echo "::error::$*"; HATALAR+=("$*"); }
grup() { echo "::group::$*"; }
grup_son() { echo "::endgroup::"; }

LOOPLAR=()
QEMU_PID=""
temizle() {
    set +e
    if [[ -n $QEMU_PID ]]; then kill "$QEMU_PID" 2>/dev/null; wait "$QEMU_PID" 2>/dev/null; fi
    for m in "$W/hedef" "$CANLI" "$KOK/proc" "$KOK/sys" "$KOK/dev"; do
        mountpoint -q "$m" && umount -R -l "$m"
    done
    for l in "${LOOPLAR[@]}"; do losetup -d "$l" 2>/dev/null; done
    for m in /dev/mapper/vabu-deneme-*; do [[ -e $m ]] && cryptsetup close "${m##*/}"; done
    chmod -R a+rX "$OUT" 2>/dev/null
}
trap temizle EXIT

grup "Araçlar"
dnf -y install python3 jq util-linux e2fsprogs dosfstools btrfs-progs cryptsetup rsync \
    procps-ng findutils tzdata glibc-langpack-tr glibc-langpack-en 'dnf-command(copr)' \
    qemu-system-x86-core seabios-bin seavgabios-bin edk2-ovmf
export DM_DISABLE_UDEV=1
grup_son

cat >"$W/arac.py" <<'PY'
# QMP (tuş, ekran görüntüsü, kapatma) ve protokol denetimi
import json, re, socket, struct, sys, time, zlib

def qmp(sock, komutlar):
    s = socket.socket(socket.AF_UNIX)
    s.settimeout(30)
    s.connect(sock)
    f = s.makefile("rw")
    json.loads(f.readline())
    def gonder(komut, arg=None):
        f.write(json.dumps({"execute": komut, **({"arguments": arg} if arg else {})}) + "\n")
        f.flush()
        while True:
            y = json.loads(f.readline())
            if "error" in y:
                raise SystemExit("QMP %s: %s" % (komut, y["error"].get("desc")))
            if "return" in y:
                return y["return"]
    gonder("qmp_capabilities")
    for k, a, bekle in komutlar:
        gonder(k, a)
        time.sleep(bekle)

def tus(ad):
    return ("send-key", {"keys": [{"type": "qcode", "data": ad}]}, 0.12)

def png_yaz(ppm, png):
    d = open(ppm, "rb").read()
    m = re.match(rb"P6\s+(\d+)\s+(\d+)\s+(\d+)\s", d)
    w, h = int(m.group(1)), int(m.group(2))
    px = d[m.end():]
    satirlar = b"".join(b"\0" + px[y * w * 3:(y + 1) * w * 3] for y in range(h))
    def parca(t, v):
        return struct.pack(">I", len(v)) + t + v + struct.pack(">I", zlib.crc32(t + v) & 0xffffffff)
    open(png, "wb").write(b"\x89PNG\r\n\x1a\n" + parca(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                          + parca(b"IDAT", zlib.compress(satirlar, 6)) + parca(b"IEND", b""))
    ornek = px[::3 * 997]
    renk = len(set(px[i:i + 3] for i in range(0, len(px) - 3, 3 * 4999)))
    print("%dx%d, siyah olmayan %%%d, renk örneği %d" % (w, h, 100 - 100 * ornek.count(0) // max(len(ornek), 1), renk))

def protokol(dosya, rc, beklenen):
    satirlar = open(dosya, encoding="utf-8").read().splitlines()
    adimlar, son, kopya, hata = [], -1, set(), []
    for s in satirlar:
        if m := re.fullmatch(r"STEP (\S+) (.+)", s):
            adimlar.append(m.group(1))
        elif m := re.fullmatch(r"PROGRESS (\d{1,3})", s):
            p = int(m.group(1))
            if p < son or p > 100:
                hata.append("ilerleme geriye ya da 100'ün üstüne gitti: %d -> %d" % (son, p))
            son = p
            if adimlar and adimlar[-1] == "copy":
                kopya.add(p)
        elif re.fullmatch(r"ERROR \S.*", s) or s == "DONE":
            pass
        else:
            hata.append("protokol dışı satır: %r" % s)
    hatalar = [s for s in satirlar if s.startswith("ERROR ")]
    if beklenen == "done":
        if adimlar != ["disk", "copy", "system", "boot", "finish"]:
            hata.append("adımlar: %s" % adimlar)
        if not satirlar or satirlar[-1] != "DONE" or rc != 0 or hatalar:
            hata.append("DONE ile bitmedi (çıkış %d, son satır %r)" % (rc, satirlar[-1:] or ""))
        if son != 100:
            hata.append("ilerleme 100'e varmadı: %d" % son)
        if len(kopya) < 20:
            hata.append("kopyalama ilerlemesi akmıyor: %d farklı değer" % len(kopya))
    else:
        if rc == 0 or len(hatalar) != 1 or satirlar[-1:] != hatalar or "DONE" in satirlar:
            hata.append("ERROR ile bitmedi (çıkış %d): %s" % (rc, satirlar[-3:]))
        elif beklenen != "error" and beklenen not in hatalar[0]:
            hata.append("beklenen hata %r, gelen %r" % (beklenen, hatalar[0]))
    print("%s: %d satır, adımlar %s, kopyalamada %d ilerleme değeri%s" % (
        dosya.rsplit("/", 1)[-1], len(satirlar), " ".join(adimlar), len(kopya),
        ", " + hatalar[0] if hatalar else ""))
    for h in hata:
        print("HATA: " + h)
    sys.exit(1 if hata else 0)

def paketler(kiwi, arch, tur):
    import xml.etree.ElementTree as ET
    for p in ET.parse(kiwi).getroot().iter("packages"):
        if p.get("type") != tur:
            continue
        for e in p.iter("package"):
            a = e.get("arch")
            if not a or arch in a.split(","):
                print(e.get("name"))

kip = sys.argv[1]
if kip == "yaz":
    harita = {" ": "spc", "-": "minus", ".": "dot", "\n": "ret"}
    qmp(sys.argv[2], [tus(harita.get(c, c)) for c in sys.argv[3]])
elif kip == "tus":
    qmp(sys.argv[2], [tus(t) for t in sys.argv[3:]])
elif kip == "ekran":
    qmp(sys.argv[2], [("screendump", {"filename": sys.argv[3]}, 0.3)])
    png_yaz(sys.argv[3], sys.argv[4])
elif kip == "kapat":
    qmp(sys.argv[2], [("quit", None, 0)])
elif kip == "durum":
    qmp(sys.argv[2], [("query-status", None, 0)])
elif kip == "protokol":
    protokol(sys.argv[2], int(sys.argv[3]), sys.argv[4])
elif kip == "paketler":
    paketler(sys.argv[2], sys.argv[3], sys.argv[4])
PY
arac() { python3 -I "$W/arac.py" "$@"; }

girdi() {  # <disk> <şifreli> <otomatik giriş> <dil> <klavye> <tür> <saat dilimi>
    jq -nc --arg disk "$1" --argjson enc "$2" --argjson oto "$3" --arg dil "$4" --arg kl "$5" \
        --arg tur "$6" --arg tz "$7" --arg pw "$PAROLA" --arg dp "$DISK_PAROLASI" '
        {disk: $disk, encrypt: $enc, passphrase: (if $enc then $dp else "" end),
         fullName: "Ada Yılmaz", login: "ada", password: $pw, hostname: "ada-vabu",
         autologin: $oto, locale: $dil, keymap: $kl, keymapVariant: $tur, timezone: $tz}'
}

yeni_disk() {  # <dosya> <boyut>: loop aygıtı YENI'ye yazılır
    rm -f "$1"
    truncate -s "$2" "$1"
    YENI=$(losetup -fP --show "$1")
    LOOPLAR+=("$YENI")
}
disk_birak() {
    losetup -d "$1"
    local yeni=() l
    for l in "${LOOPLAR[@]}"; do [[ $l == "$1" ]] || yeni+=("$l"); done
    LOOPLAR=("${yeni[@]}")
}

# --- 1. hızlı denetimler -------------------------------------------------------------------

grup "Hızlı denetimler (--disks, --dry-run, hatalı girdiler)"
bash -n "$BETIK" || basarisiz "install-system sözdizimi hatalı"
yeni_disk "$W/bos.img" 24G; D1=$YENI
yeni_disk "$W/kucuk.img" 8G; D2=$YENI
export VABU_INSTALL_SOURCE=/yok VABU_INSTALL_TEST=1 VABU_INSTALL_FIRMWARE=uefi
bash "$BETIK" --disks | tee "$OUT/diskler.json"
jq -e --arg a "$D1" --arg b "$D2" '
    type == "array"
    and all(.[]; (keys | sort) == ["model", "path", "removable", "size", "tooSmall", "transport"])
    and any(.[]; .path == $a and .tooSmall == false and .size == 25769803776)
    and any(.[]; .path == $b and .tooSmall == true)' "$OUT/diskler.json" >/dev/null ||
    basarisiz "--disks çıktısı beklendiği gibi değil"
VABU_INSTALL_TEST=0 bash "$BETIK" --disks | jq -e --arg a "$D1" 'all(.[]; .path != $a)' >/dev/null ||
    basarisiz "--disks loop aygıtlarını listeliyor"
setpriv --reuid=65534 --regid=65534 --clear-groups bash "$BETIK" --disks | jq -e 'type == "array"' >/dev/null ||
    basarisiz "--disks root olmadan çalışmıyor"

dene() {  # <ad> <beklenen: done|error|hata metni> <girdi> [ek ortam ...]
    local ad=$1 bek=$2 gir=$3 rc=0 bas=$SECONDS
    shift 3
    printf '%s' "$gir" | env "$@" bash "$BETIK" --dry-run >"$OUT/kuru-$ad.txt" 2>"$OUT/kuru-$ad.err" || rc=$?
    echo "--- $ad ($((SECONDS - bas)) sn)"
    arac protokol "$OUT/kuru-$ad.txt" "$rc" "$bek" || basarisiz "deneme kipi: $ad"
}
iyi=$(girdi "$D1" false false tr_TR.UTF-8 tr "" Europe/Istanbul)
bas=$SECONDS
dene gecerli done "$iyi"
(( SECONDS - bas >= 15 && SECONDS - bas <= 40 )) || basarisiz "deneme kipi süresi: $((SECONDS - bas)) sn"
if blkid -p "$D1" >/dev/null 2>&1 || [[ -n $(head -c 1048576 "$W/bos.img" | tr -d '\0' | head -c 1) ]]; then
    basarisiz "deneme kipi diske dokundu"
fi
dene sifreli done "$(girdi "$D1" true true en_US.UTF-8 us "" UTC)"
dene adim-hatasi "Deneme hatası (copy)" "$iyi" VABU_INSTALL_DRYRUN_FAIL=copy
dene bozuk-json "Kurulum bilgisi okunamadı" '{"disk": "/dev/x",'
dene tip-hatasi "Kurulum bilgisi okunamadı" "$(jq -c '.encrypt = "evet"' <<<"$iyi")"
dene kullanici "Kullanıcı adı geçersiz" "$(jq -c '.login = "Ada"' <<<"$iyi")"
dene kullanici-var "Bu kullanıcı adı kullanılamaz" "$(jq -c '.login = "root"' <<<"$iyi")"
dene parola "Parola boş olamaz" "$(jq -c '.password = ""' <<<"$iyi")"
dene disk-parolasi "Disk şifresi boş olamaz" "$(jq -c '.encrypt = true | .passphrase = ""' <<<"$iyi")"
dene makine "Bilgisayar adı geçersiz" "$(jq -c '.hostname = "ada_vabu"' <<<"$iyi")"
dene dil "Dil seçimi geçersiz" "$(jq -c '.locale = "turkce"' <<<"$iyi")"
dene saat "Saat dilimi bulunamadı" "$(jq -c '.timezone = "Europe/Ankara"' <<<"$iyi")"
dene kontrol-karakteri "Kurulum bilgisi okunamadı" "$(jq -c '.fullName = "Ada\nYılmaz"' <<<"$iyi")"
dene disk-yok "Disk bulunamadı" "$(jq -c '.disk = "/dev/yok"' <<<"$iyi")"
dene disk-kucuk "Disk çok küçük" "$(jq -c --arg d "$D2" '.disk = $d' <<<"$iyi")"
dene disk-loop "Bu diske kurulum yapılamaz" "$iyi" VABU_INSTALL_TEST=0
printf '%s' "$iyi" | bash "$BETIK" --bilinmeyen >"$OUT/kuru-secenek.txt" 2>&1 && basarisiz "bilinmeyen seçenek kabul edildi"
if grep -qF -e "$PAROLA" -e "$DISK_PAROLASI" /tmp/vabu-install.log; then basarisiz "parola kayda yazıldı (deneme kipi)"; fi
unset VABU_INSTALL_SOURCE VABU_INSTALL_TEST VABU_INSTALL_FIRMWARE
disk_birak "$D1"; disk_birak "$D2"
rm -f "$W/bos.img" "$W/kucuk.img"
grup_son

# --- 2. canlı imaja benzeyen kök -----------------------------------------------------------

kok_bagla() {
    mount -t proc proc "$1/proc"
    mount -t sysfs sys "$1/sys"
    mount --bind /dev "$1/dev"
}
kok_ayir() { umount "$1/dev" "$1/sys" "$1/proc"; }

if [[ ! -f $W/kok.hazir ]]; then
    grup "Canlı imaj kökü (dnf --installroot)"
    v=$FEDORA
    dnf -y install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$v.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$v.noarch.rpm"
    dnf -y copr enable "$(cat "$REPO/COPR_OWNER")/vabu"
    arac paketler "$REPO/iso/config.kiwi" "$ARCH" bootstrap >"$W/paket-bootstrap.txt"
    arac paketler "$REPO/iso/config.kiwi" "$ARCH" image >"$W/paket-imaj.txt"
    rm -rf "$KOK"
    mkdir -p "$KOK"
    # Kiwi gibi: önerilen paketler de gelsin, imzalar denetlenmesin (rpm-check-signatures=false)
    DNF=(dnf -y --installroot="$KOK" --use-host-config --releasever="$FEDORA" --no-gpgchecks
        --setopt=install_weak_deps=True --setopt=keepcache=False)
    "${DNF[@]}" install $(cat "$W/paket-bootstrap.txt")
    mkdir -p "$KOK/proc" "$KOK/sys" "$KOK/dev"
    kok_bagla "$KOK"
    "${DNF[@]}" install $(cat "$W/paket-imaj.txt")
    "${DNF[@]}" clean all || true
    kok_ayir "$KOK"
    rpm --root="$KOK" -qa | sort >"$OUT/canli-paketler.txt"
    wc -l <"$OUT/canli-paketler.txt"

    # Kiwi: iso/root kökün üstüne kopyalanır, <preferences> uygulanır, config.sh çalışır
    cp -a "$REPO/iso/root/." "$KOK/"
    install -m 0755 "$BETIK" "$KOK/usr/libexec/vabu/install-system"
    echo 'KEYMAP=trq' >"$KOK/etc/vconsole.conf"
    ln -sfn ../usr/share/zoneinfo/Europe/Istanbul "$KOK/etc/localtime"
    # Kiwi'nin canlı açılış imajı için yazdığı dracut ayarı
    printf 'add_dracutmodules+=" dmsquash-live livenet pollcdrom "\nomit_dracutmodules+=" multipath "\n' \
        >"$KOK/etc/dracut.conf.d/02-livecd.conf"
    kok_bagla "$KOK"
    cp "$REPO/iso/config.sh" "$KOK/tmp/config.sh"
    chroot "$KOK" bash /tmp/config.sh
    rm -f "$KOK/tmp/config.sh"
    kok_ayir "$KOK"
    rm -rf "${KOK:?}"/run/* "${KOK:?}"/tmp/*
    du -sh --exclude=proc --exclude=sys --exclude=dev "$KOK"
    ls -la "$KOK/boot" "$KOK/boot/loader/entries" "$KOK/boot/efi/EFI"/* || true
    touch "$W/kok.hazir"
    grup_son
else
    install -m 0755 "$BETIK" "$KOK/usr/libexec/vabu/install-system"
fi

# --- 3. canlı oturum: overlay + /run/rootfsbase ---------------------------------------------

grup "Canlı oturum ortamı"
rm -rf "$W/ust" "$W/is"
mkdir -p "$W/ust" "$W/is" "$CANLI"
mount -t overlay overlay -o "lowerdir=$KOK,upperdir=$W/ust,workdir=$W/is" "$CANLI"
kok_bagla "$CANLI"
mount -t tmpfs tmpfs "$CANLI/run"
mkdir -p "$CANLI/run/rootfsbase" "$CANLI/mnt/kaynak"
mount --bind "$KOK" "$CANLI/run/rootfsbase"
mount -o remount,bind,ro "$CANLI/run/rootfsbase"
# bios denemesi kaynağı VABU_INSTALL_SOURCE ile başka bir yerden alır
mount --bind "$KOK" "$CANLI/mnt/kaynak"
mount -o remount,bind,ro "$CANLI/mnt/kaynak"
# Canlı oturumda kaydedilmiş bir bağlantı: kurulan sisteme yeni kullanıcıyla geçmeli
install -d -m 0700 "$CANLI/etc/NetworkManager/system-connections"
cat >"$CANLI/etc/NetworkManager/system-connections/vabu-deneme.nmconnection" <<'NM'
[connection]
id=vabu-deneme
uuid=6c5b6c1e-1f0e-4c7e-9b51-0f6d3f1d2a11
type=ethernet
permissions=user:liveuser:;

[ipv4]
method=auto
NM
chmod 0600 "$CANLI/etc/NetworkManager/system-connections/vabu-deneme.nmconnection"
findmnt -R "$CANLI" | head -n 20
grup_son

# --- 4-5. kurulum ve açılış ------------------------------------------------------------------

ovmf_bul() {
    local d k
    for d in /usr/share/edk2/ovmf /usr/share/OVMF /usr/share/edk2/x64; do
        for k in OVMF_CODE.fd OVMF_CODE_4M.fd OVMF_CODE.4m.fd OVMF_CODE_4M.qcow2; do
            [[ -f $d/$k && -f $d/${k/CODE/VARS} ]] || continue
            echo "$d/$k $d/${k/CODE/VARS}"
            return 0
        done
    done
    return 1
}
if [[ -r /dev/kvm && -w /dev/kvm ]]; then HIZ=(-accel kvm -cpu host); SURE=900; else HIZ=(-accel tcg -cpu max); SURE=2700; fi
echo "QEMU: $(qemu-system-x86_64 --version | head -n1), hızlandırma: ${HIZ[1]}"

kur() {  # <deneme> <firmware> <disk> <girdi> [kaynak]
    local d=$1 rc=0 ortam=(DM_DISABLE_UDEV=1 VABU_INSTALL_TEST=1 "VABU_INSTALL_FIRMWARE=$2"
        "VABU_INSTALL_CMDLINE=$EK_SATIR" "VABU_INSTALL_DRIVERS=$SURUCULER")
    if [[ -n ${5:-} ]]; then ortam+=("VABU_INSTALL_SOURCE=$5"); fi
    printf '%s' "$4" | chroot "$CANLI" runuser -u liveuser -- \
        sudo -n env "${ortam[@]}" /usr/libexec/vabu/install-system \
        >"$OUT/$d-protokol.txt" 2>"$OUT/$d-stderr.txt" || rc=$?
    cp "$CANLI/tmp/vabu-install.log" "$OUT/$d-kurulum.log" || true
    cat "$OUT/$d-stderr.txt"
    tail -n 40 "$OUT/$d-kurulum.log" || true
    arac protokol "$OUT/$d-protokol.txt" "$rc" done
}

hedef_denetle() {  # <deneme> <firmware> <loop> <şifreli> <otomatik> <konsol klavyesi> <xkb düzeni> <saat dilimi>
    local d=$1 fw=$2 l=$3 sif=$4 oto=$5 kon=$6 xkb=$7 tz=$8 h=$W/hedef kokdev ru bu eu luks="" e
    sorun() { basarisiz "$d: $*"; }
    kokdev=${l}p3
    if [[ $sif == true ]]; then
        luks=$(blkid -c /dev/null -s UUID -o value "${l}p3")
        printf '%s' "$DISK_PAROLASI" | cryptsetup open --key-file=- "${l}p3" "vabu-deneme-$d" ||
            { sorun "disk şifresi açılamadı"; return; }
        kokdev=/dev/mapper/vabu-deneme-$d
    fi
    ru=$(blkid -c /dev/null -s UUID -o value "$kokdev")
    bu=$(blkid -c /dev/null -s UUID -o value "${l}p2")
    mkdir -p "$h"
    mount -o subvol=root,ro "$kokdev" "$h"
    mount -o subvol=home,ro "$kokdev" "$h/home"
    mount -o subvol=var/log,ro "$kokdev" "$h/var/log"
    mount -o ro "${l}p2" "$h/boot"
    if [[ $fw == uefi ]]; then
        eu=$(blkid -c /dev/null -s UUID -o value "${l}p1")
        mount -o ro "${l}p1" "$h/boot/efi"
    fi
    {
        echo "== bölümler"; sfdisk -d "$l"; lsblk -o NAME,SIZE,FSTYPE,UUID,PARTTYPENAME "$l"
        btrfs subvolume list "$h" || true
        for f in etc/fstab etc/crypttab etc/kernel/cmdline etc/default/grub etc/locale.conf etc/vconsole.conf \
            etc/X11/xorg.conf.d/00-keyboard.conf etc/hostname etc/hosts etc/greetd/vabu.toml \
            boot/efi/EFI/fedora/grub.cfg home/ada/.config/vabu/niri.json; do
            echo "== $f"; cat "$h/$f" 2>&1 || true
        done
        echo "== BLS"; head -n 20 "$h"/boot/loader/entries/*.conf
        echo "== /boot"; ls -la "$h/boot"
        [[ $fw == uefi ]] && { echo "== ESP"; find "$h/boot/efi" -type f | sort; }
        echo "== localtime"; readlink "$h/etc/localtime"
        echo "== kullanıcılar"; grep -E '^(ada|liveuser|root):' "$h/etc/passwd" "$h/etc/group" || true
    } >"$OUT/$d-hedef.txt" 2>&1
    grep -q "^UUID=$ru  */  *btrfs  *subvol=root,compress=zstd:1" "$h/etc/fstab" || sorun "fstab: kök"
    grep -q "^UUID=$bu  */boot  *ext4" "$h/etc/fstab" || sorun "fstab: /boot"
    grep -q "^UUID=$ru  */home  *btrfs  *subvol=home" "$h/etc/fstab" || sorun "fstab: /home"
    grep -q "^UUID=$ru  */var/log  *btrfs  *subvol=var/log" "$h/etc/fstab" || sorun "fstab: /var/log"
    if [[ $fw == uefi ]]; then
        grep -q "^UUID=$eu  */boot/efi  *vfat" "$h/etc/fstab" || sorun "fstab: /boot/efi"
        grep -q "search --no-floppy --fs-uuid --set=dev $bu" "$h/boot/efi/EFI/fedora/grub.cfg" || sorun "EFI grub.cfg"
        [[ -f $h/boot/efi/EFI/BOOT/BOOTX64.EFI && -f $h/boot/efi/EFI/fedora/shimx64.efi ]] || sorun "EFI yedek yolu"
        cmp -s "$h/boot/efi/EFI/BOOT/BOOTX64.EFI" "$h/boot/efi/EFI/fedora/shimx64.efi" || sorun "BOOTX64.EFI shim değil"
    else
        head -c 512 "$l" | grep -aq GRUB || sorun "MBR'de GRUB yok"
        [[ -f $h/boot/grub2/i386-pc/core.img ]] || sorun "grub2 i386-pc kurulmamış"
    fi
    if [[ $sif == true ]]; then
        grep -q "^luks-$luks UUID=$luks none" "$h/etc/crypttab" || sorun "crypttab"
    fi
    local girdiler=("$h"/boot/loader/entries/*.conf) k
    [[ -f ${girdiler[0]} ]] || sorun "BLS girdisi yok"
    for e in "${girdiler[@]}"; do
        grep -q "^options .*root=UUID=$ru .*rootflags=subvol=root" "$e" || sorun "BLS satırı: ${e##*/}"
        grep -qE 'root=live:|rd\.live' "$e" && sorun "BLS satırında canlı ayar: ${e##*/}"
        [[ $sif == true ]] && ! grep -q "rd.luks.uuid=luks-$luks" "$e" && sorun "BLS satırında rd.luks.uuid yok"
        [[ ${e##*/} == "$(cat "$h/etc/machine-id")"-* ]] || sorun "BLS girdisi eski makine kimliğiyle: ${e##*/}"
    done
    for k in "$h"/usr/lib/modules/*/vmlinuz; do
        k=${k%/vmlinuz}; k=${k##*/}
        [[ -s $h/boot/initramfs-$k.img && -f $h/boot/vmlinuz-$k ]] || sorun "çekirdek/initramfs eksik: $k"
        cp "$h/boot/initramfs-$k.img" "$CANLI/tmp/ilk.img"
        chroot "$CANLI" lsinitrd -m /tmp/ilk.img >"$OUT/$d-initramfs.txt" 2>&1 || true
        rm -f "$CANLI/tmp/ilk.img"
        grep -qE '^(dmsquash-live|livenet|pollcdrom)$' "$OUT/$d-initramfs.txt" && sorun "initramfs canlı modül içeriyor"
        grep -qx btrfs "$OUT/$d-initramfs.txt" || sorun "initramfs btrfs içermiyor"
        [[ $sif == true ]] && ! grep -qx crypt "$OUT/$d-initramfs.txt" && sorun "initramfs crypt içermiyor"
    done
    grep -q 'blscfg' "$h/boot/grub2/grub.cfg" || sorun "grub.cfg blscfg içermiyor"
    grep -q 'themes/vabu/theme.txt' "$h/boot/grub2/grub.cfg" || sorun "grub.cfg tema içermiyor"
    [[ $(cat "$h/etc/machine-id") =~ ^[0-9a-f]{32}$ ]] || sorun "machine-id"
    if cmp -s "$h/etc/machine-id" "$KOK/etc/machine-id"; then sorun "machine-id canlı imajla aynı"; fi
    grep -q '^ada:x:1000:1000:Ada Yılmaz:/home/ada:/bin/bash$' "$h/etc/passwd" || sorun "kullanıcı ada"
    grep -qE '^wheel:.*[:,]ada(,|$)' "$h/etc/group" || sorun "ada wheel grubunda değil"
    grep -q '^liveuser:' "$h/etc/passwd" "$h/etc/group" "$h/etc/shadow" && sorun "liveuser silinmemiş"
    [[ -e $h/home/liveuser ]] && sorun "/home/liveuser duruyor"
    [[ -d $h/home/ada ]] || sorun "/home/ada yok"
    grep -qE '^ada:\$[a-z0-9]+\$' "$h/etc/shadow" || sorun "ada parolası ayarlanmamış"
    grep -qE '^root:!' "$h/etc/shadow" || sorun "root kilitli değil"
    [[ -e $h/etc/sudoers.d/10-liveuser ]] && sorun "canlı sudo kuralı duruyor"
    [[ -e $h/usr/share/applications/vabu-kur.desktop ]] && sorun "kurulum başlatıcısı duruyor"
    [[ -e $h/etc/dracut.conf.d/02-livecd.conf ]] && sorun "canlı dracut ayarı duruyor"
    [[ -e $h/.autorelabel ]] || sorun ".autorelabel yok"
    if [[ $oto == true ]]; then
        grep -A2 '^\[initial_session\]' "$h/etc/greetd/vabu.toml" | grep -q 'user = "ada"' || sorun "otomatik giriş"
    else
        grep -q initial_session "$h/etc/greetd/vabu.toml" && sorun "greetd'de otomatik giriş kalmış"
        cmp -s "$h/etc/greetd/vabu.toml" "$h/usr/share/vabu/greetd/vabu.toml" || sorun "greetd ayarı"
    fi
    [[ $(readlink "$h/etc/systemd/system/default.target") == */graphical.target ]] || sorun "varsayılan hedef"
    [[ -e $h/etc/systemd/system/display-manager.service || -e $h/etc/systemd/system/multi-user.target.wants/greetd.service ]] ||
        sorun "greetd etkin değil"
    for e in vabu-flatpak-setup.service vabu-snapper-setup.service NetworkManager.service; do
        compgen -G "$h/etc/systemd/system/*.wants/$e" >/dev/null || sorun "$e etkin değil"
    done
    compgen -G "$h/etc/systemd/system/timers.target.wants/vabu-update.timer" >/dev/null || sorun "vabu-update.timer etkin değil"
    grep -qx "KEYMAP=$kon" "$h/etc/vconsole.conf" || sorun "vconsole.conf"
    grep -q "\"XkbLayout\" \"$xkb\"" "$h/etc/X11/xorg.conf.d/00-keyboard.conf" || sorun "X11 klavye"
    grep -q "layout \"$xkb\"" "$h/home/ada/.config/niri/config.kdl" || sorun "kullanıcının niri klavyesi"
    [[ $(stat -c %u "$h/home/ada/.config/niri/config.kdl") == 1000 ]] || sorun "niri ayarının sahibi"
    [[ $(readlink "$h/etc/localtime") == ../usr/share/zoneinfo/$tz ]] || sorun "saat dilimi"
    grep -qx ada-vabu "$h/etc/hostname" || sorun "hostname"
    grep -q 'permissions=user:ada:;' "$h/etc/NetworkManager/system-connections/vabu-deneme.nmconnection" ||
        sorun "canlı oturumdaki ağ bağlantısı taşınmadı"
    [[ -f $h/var/log/vabu-install.log ]] || sorun "hedefte kurulum kaydı yok"
    if grep -rIlsF -e "$PAROLA" -e "$DISK_PAROLASI" "$h/etc" "$h/var/log" "$h/root" "$OUT/$d-kurulum.log" "$CANLI/tmp"; then
        sorun "parola düz metin olarak yazılmış"
    fi
    umount -R "$h"
    if [[ $sif == true ]]; then cryptsetup close "vabu-deneme-$d"; fi
}

seri_var() { grep -aqE "$1" "$SERI" 2>/dev/null; }

ac() {  # <deneme> <firmware> <disk dosyası> <şifreli> <otomatik>
    local d=$1 fw=$2 img=$3 sif=$4 oto=$5 sock=$W/qmp.sock fw_arg=() bas=$SECONDS bitis
    local luks_yazildi=0 luks_zaman=0 giris_den=0 giris_zaman=0 greeter=0 tamam=0 sonuc=""
    SERI=$OUT/$d-seri.log
    rm -f "$sock" "$SERI" "$OUT/$d"-*.png
    if [[ $fw == uefi ]]; then
        local code vars
        read -r code vars < <(ovmf_bul)
        local bicim=raw; [[ $code == *.qcow2 ]] && bicim=qcow2
        cp "$vars" "$W/vars-$d"
        fw_arg=(-drive "if=pflash,unit=0,format=$bicim,readonly=on,file=$code"
            -drive "if=pflash,unit=1,format=$bicim,file=$W/vars-$d")
    fi
    qemu-system-x86_64 -name "vabu-$d" -machine q35 "${HIZ[@]}" -m 4096 -smp 4 \
        -nodefaults -nic none -display none -device VGA,edid=on,xres=1280,yres=800 \
        "${fw_arg[@]}" \
        -drive "if=none,id=disk,format=raw,file=$img,cache=unsafe" -device virtio-blk-pci,drive=disk,bootindex=1 \
        -serial "file:$SERI" -qmp "unix:$sock,server=on,wait=off" >"$OUT/$d-qemu.log" 2>&1 &
    QEMU_PID=$!
    bitis=$((SECONDS + SURE))
    while (( SECONDS < bitis )); do
        sleep 5
        if ! kill -0 "$QEMU_PID" 2>/dev/null; then sonuc="QEMU kapandı"; break; fi
        if seri_var 'Kernel panic|Entering emergency mode|You are in emergency mode|dracut-initqueue.*timeout'; then
            sonuc="açılış başarısız (seri kayıt)"; sleep 10; break
        fi
        if [[ $sif == true ]] && ! seri_var 'Finished.*[Cc]ryptography [Ss]etup|Finished systemd-cryptsetup'; then
            if seri_var 'Cryptography Setup for luks|[Pp]assphrase for' &&
                (( ! luks_yazildi || (SECONDS - luks_zaman > 60 && luks_yazildi < 3) )); then
                sleep 5
                arac ekran "$sock" "$W/ekran.ppm" "$OUT/$d-1-disk-sifresi.png" || true
                echo "disk şifresi yazılıyor ($((SECONDS - bas)). sn)"
                arac yaz "$sock" "$DISK_PAROLASI"$'\n' || true
                luks_yazildi=$((luks_yazildi + 1))
                luks_zaman=$SECONDS
            fi
            continue
        fi
        if (( ! greeter )) && seri_var 'session opened for user greetd'; then
            greeter=$SECONDS
            echo "giriş ekranı oturumu açıldı ($((SECONDS - bas)). sn)"
        fi
        if seri_var 'session opened for user ada'; then
            echo "ada oturum açtı ($((SECONDS - bas)). sn)"
            tamam=1
            sleep 30
            arac ekran "$sock" "$W/ekran.ppm" "$OUT/$d-3-masaustu.png" || true
            break
        fi
        if [[ $oto == false ]] && (( greeter && SECONDS - greeter > 25 && giris_den < 6 &&
            SECONDS - giris_zaman > 40 )); then
            arac ekran "$sock" "$W/ekran.ppm" "$OUT/$d-2-giris-ekrani.png" || true
            echo "parola yazılıyor ($((SECONDS - bas)). sn)"
            arac tus "$sock" esc || true
            sleep 1
            arac yaz "$sock" "$PAROLA"$'\n' || true
            giris_den=$((giris_den + 1))
            giris_zaman=$SECONDS
        fi
    done
    if (( ! tamam )); then
        [[ -n $sonuc ]] || sonuc="$SURE saniyede oturum açılamadı"
        arac ekran "$sock" "$W/ekran.ppm" "$OUT/$d-9-son.png" || true
    fi
    arac kapat "$sock" 2>/dev/null || true
    sleep 2
    kill "$QEMU_PID" 2>/dev/null || true
    wait "$QEMU_PID" 2>/dev/null || true
    QEMU_PID=""
    sed 's/\x1b\[[0-9;?]*[A-Za-z]//g' "$SERI" | tr -d '\000-\010\013-\037' >"$OUT/$d-seri.txt" || true
    echo "seri kayıt: $(wc -l <"$OUT/$d-seri.txt") satır; önemli satırlar:"
    grep -aE 'greetd|session opened|cryptsetup|[Rr]elabel|Failed|niri|quickshell|qs\[' "$OUT/$d-seri.txt" |
        grep -v 'audit' | head -n 60 || true
    if (( tamam )); then
        if (( greeter == 0 )) && [[ $oto == false ]]; then basarisiz "$d: giriş ekranı izi seri kayıtta yok"; fi
        echo "$d: açılış tamam ($((SECONDS - bas)) sn)"
    else
        tail -n 80 "$OUT/$d-seri.txt" || true
        basarisiz "$d: $sonuc"
    fi
}

for d in "${DENEMELER[@]}"; do
    case $d in
        uefi)          fw=uefi sif=false oto=false dil=tr_TR.UTF-8 kl=tr tur="" kon=trq tz=Europe/Istanbul kaynak="" ;;
        uefi-sifreli)  fw=uefi sif=true  oto=true  dil=en_US.UTF-8 kl=us tur="" kon=us  tz=Europe/Berlin   kaynak="" ;;
        bios)          fw=bios sif=false oto=false dil=tr_TR.UTF-8 kl=tr tur=f  kon=trf tz=Europe/Istanbul kaynak=/mnt/kaynak ;;
        *) basarisiz "bilinmeyen deneme: $d"; continue ;;
    esac
    grup "Kurulum: $d"
    img=$W/disk-$d.img
    yeni_disk "$img" 24G; l=$YENI
    bas=$SECONDS
    if kur "$d" "$fw" "$l" "$(girdi "$l" "$sif" "$oto" "$dil" "$kl" "$tur" "$tz")" "$kaynak"; then
        echo "kurulum $((SECONDS - bas)) sn"
        hedef_denetle "$d" "$fw" "$l" "$sif" "$oto" "$kon" "$kl" "$tz" || basarisiz "$d: hedef denetimi yarıda kaldı"
        cat "$OUT/$d-hedef.txt"
        grup_son
        disk_birak "$l"
        grup "Açılış: $d"
        ac "$d" "$fw" "$img" "$sif" "$oto"
    else
        basarisiz "$d: kurulum başarısız"
        disk_birak "$l"
    fi
    grup_son
    rm -f "$img"
done

if (( ${#HATALAR[@]} )); then
    printf 'BAŞARISIZ: %s\n' "${HATALAR[@]}"
    exit 1
fi
echo "Tüm denemeler geçti: ${DENEMELER[*]}"

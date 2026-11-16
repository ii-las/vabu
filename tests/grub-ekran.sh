#!/usr/bin/env bash
# Önyükleme menüsünü (GRUB) kurulu Vabu temasıyla QEMU içinde açar ve görüntülerini alır.
# Önce temayı denetler: theme.txt'de geçen yazı tipi adları .pf2 dosyalarının içindeki
# adlarla, görseller de klasördeki dosyalarla karşılaştırılır.
#
#   tests/grub-ekran.sh [çıktı klasörü]
#
# Vabu paketleri kurulu bir Fedora'da çalışır (CI bunu her derlemede yapar). KVM gerekmez.
# Gerekenler: qemu-system-x86-core edk2-ovmf grub2-tools-extra grub2-efi-x64-modules
#             mtools ImageMagick python3   (eksik olan dnf ile kurulmaya çalışılır)
#
# Yalnızca temadaki bir hata derlemeyi durdurur. Araç eksikse ya da QEMU açılamazsa
# uyarı verilip geçilir.
set -uo pipefail

OUT="${1:-/tmp/ekran}"
TEMA="${VABU_GRUB_TEMA:-/boot/grub2/themes/vabu}"
MODDIR=/usr/lib/grub/x86_64-efi
BEKLEME="${VABU_GRUB_BEKLEME:-110}"     # menünün çizilmesi için en çok beklenecek saniye
mkdir -p "$OUT"
rm -f "$OUT"/6[0-2]-grub*.png "$OUT"/grub-*.log
durum=0

atla() { echo "::warning::önyükleme menüsünün görüntüsü alınamadı: $*"; exit "$durum"; }

if [[ ! -f "$TEMA/theme.txt" ]]; then
    echo "::error::GRUB teması yok: $TEMA/theme.txt"
    exit 1
fi

# OVMF'nin yeri ve dosya adları dağıtıma, sürüme göre değişiyor.
# Secure Boot'suz ilk CODE/VARS çifti alınır.
ovmf_bul() {
    local d k
    for d in /usr/share/edk2/ovmf /usr/share/OVMF /usr/share/edk2/x64; do
        for k in OVMF_CODE.fd OVMF_CODE_4M.fd OVMF_CODE.4m.fd OVMF_CODE_4M.qcow2; do
            [[ -f "$d/$k" && -f "$d/${k/CODE/VARS}" ]] || continue
            echo "$d/$k $d/${k/CODE/VARS}"
            return 0
        done
    done
    return 1
}

eksikler() {
    command -v python3 >/dev/null            || echo python3
    command -v magick >/dev/null             || echo ImageMagick
    command -v qemu-system-x86_64 >/dev/null || echo qemu-system-x86-core
    command -v grub2-mkstandalone >/dev/null || echo grub2-tools-extra
    command -v mformat >/dev/null            || echo mtools
    [[ -f "$MODDIR/normal.mod" ]]            || echo grub2-efi-x64-modules
    ovmf_bul >/dev/null                      || echo edk2-ovmf
}
eksik=($(eksikler))
if (( ${#eksik[@]} )) && command -v dnf >/dev/null && (( EUID == 0 )); then
    echo "eksik paketler kuruluyor: ${eksik[*]}"
    dnf -y install --setopt=install_weak_deps=False "${eksik[@]}" || echo "dnf kurulumu başarısız"
    eksik=($(eksikler))
fi

# GRUB, adı tutmayan yazı tipinde hata vermez, sessizce başka bir yazı tipini kullanır.
# Bu yüzden adlar .pf2 dosyalarının içinden okunur: dosya "FILE" <4> "PFF2" ile başlar,
# ardından "NAME" <4 bayt uzunluk> <ad> gelir. Çıkış kodu 3: temada hata var.
tema_denetle() {
    python3 - "$TEMA" <<'PY'
import glob, os, re, struct, sys

tema, hata, adlar = sys.argv[1], 0, set()
for yol in sorted(glob.glob(os.path.join(tema, "*.pf2"))):
    d = open(yol, "rb").read(4096)
    if d[:4] != b"FILE" or d[8:16] != b"PFF2NAME":
        print("::error::geçersiz .pf2 dosyası: " + yol)
        hata = 3
        continue
    n = struct.unpack(">I", d[16:20])[0]
    ad = d[20:20 + n].split(b"\0")[0].decode("utf-8", "replace")
    adlar.add(ad)
    print('%s: "%s"' % (os.path.basename(yol), ad))

parcalar = "nw n ne w c e sw s se".split()
bilesen, sayac = "genel", None
for no, satir in enumerate(open(os.path.join(tema, "theme.txt"), encoding="utf-8", errors="replace"), 1):
    if satir.lstrip().startswith("#"):
        continue
    m = re.match(r"\s*\+\s*(\w+)", satir)
    if m:
        bilesen = m.group(1)
    if re.search(r'\bid\s*=\s*"__timeout__"', satir):
        sayac = "%s (satır %d)" % (bilesen, no)
    m = re.match(r'\s*([\w-]*font)\s*[:=]\s*"([^"]*)"', satir)
    if m and m.group(2) != "inherit":
        tamam = m.group(2) in adlar
        print('theme.txt:%d: %s "%s"%s' % (no, m.group(1), m.group(2), "" if tamam else "  <- yok"))
        if not tamam:
            print('::error::theme.txt:%d: "%s" hiçbir .pf2 dosyasındaki adla eşleşmiyor' % (no, m.group(2)))
            hata = 3
    # file, desktop-image ve *_style değerleri. Yıldızlı ad dokuz parçalı kutudur
    # (select_*.png -> select_nw.png ...); GRUB eksik parçayı hoş görür, biri yeter.
    for a, b in re.findall(r'[:=]\s*(?:"([^"]+\.(?:png|jpe?g|tga))"|([^\s"{}]+\.(?:png|jpe?g|tga)))',
                           satir, re.I):
        ad = a or b
        if ad.startswith(("/", "(")):
            continue
        dosyalar = [ad.replace("*", p) for p in parcalar] if "*" in ad else [ad]
        var = [f for f in dosyalar if os.path.isfile(os.path.join(tema, f))]
        print("theme.txt:%d: %s %s (%d/%d dosya)" % (no, bilesen, ad, len(var), len(dosyalar)))
        if not var:
            print("::error::theme.txt:%d: görsel yok: %s" % (no, ad))
            hata = 3
print("geri sayım: " + (sayac or "yok (__timeout__ kimlikli bileşen tanımlanmamış)"))
sys.exit(hata)
PY
}
if command -v python3 >/dev/null; then
    echo "=== tema denetimi: $TEMA"
    tema_denetle
    case $? in
        0) ;;
        3) durum=1 ;;
        *) echo "::warning::tema denetimi çalıştırılamadı" ;;
    esac
fi
(( ${#eksik[@]} == 0 )) || atla "eksik araç: ${eksik[*]}"

read -r OVMF_CODE OVMF_VARS < <(ovmf_bul)
BICIM=raw; [[ "$OVMF_CODE" == *.qcow2 ]] && BICIM=qcow2
echo "=== araçlar"
echo "QEMU: $(qemu-system-x86_64 --version | head -n 1)"
echo "GRUB: $(grub2-mkstandalone --version), modüller: $MODDIR"
echo "OVMF: $OVMF_CODE ($BICIM)"

TMP="$(mktemp -d)"
SOCK="$TMP/qmp.sock"
QEMU_PID=""
qemu_durdur() {
    [[ -n "$QEMU_PID" ]] || return 0
    kill "$QEMU_PID" 2>/dev/null
    wait "$QEMU_PID" 2>/dev/null
    QEMU_PID=""
}
temizle() { qemu_durdur; rm -rf "$TMP"; }
trap temizle EXIT
trap 'exit 130' INT TERM

# grub.cfg: Fedora'nın ürettiği dosyadaki adımlar (ekran modülleri, yazı tipleri, gfxterm,
# tema). unicode en son yüklenir ki tema açılana kadar gfxterm onu kullansın. Girişler
# hiçbir şey başlatmaz. echo ve videoinfo çıktısı grafik kipine geçmeden önce yazıldığı
# için OVMF üzerinden seri kayda da düşer.
CFG="$OUT/grub-ekran.cfg"
{
    echo 'echo "VABU_GRUB: ayar dosyasi okunuyor"'
    for m in all_video efi_gop gfxterm gfxmenu png jpeg; do
        if [[ -f "$MODDIR/$m.mod" ]]; then echo "insmod $m"; else echo "GRUB modülü yok: $m" >&2; fi
    done
    for f in "$TEMA"/*.pf2; do
        [[ -f "$f" ]] && echo "loadfont \$prefix/themes/vabu/${f##*/}"
    done
    cat <<'CFG'
if [ -f $prefix/fonts/unicode.pf2 ]; then
    loadfont unicode
fi
set gfxmode=1920x1080x32,1920x1080,auto
videoinfo
echo "VABU_GRUB: grafik kipine geciliyor"
terminal_output gfxterm
set theme=$prefix/themes/vabu/theme.txt
set default=0
set timeout_style=menu
set timeout=30
CFG
    for baslik in "Vabu" "Vabu (önceki çekirdek)" "Vabu (kurtarma kipi)" "UEFI ayarları"; do
        printf 'menuentry "%s" {\n    true\n}\n' "$baslik"
    done
} > "$CFG"
if command -v grub2-script-check >/dev/null && ! grub2-script-check "$CFG"; then
    echo "::warning::üretilen grub.cfg sözdizimi denetiminden geçmedi ($CFG)"
fi

# İmaj: grub2-mkstandalone bütün modülleri, grub.cfg'yi ve temayı tek bir EFI dosyasının
# içine (memdisk) koyar; o dosya da mtools ile bölümsüz bir FAT imajına yazılır. İkisi de
# düz dosya üzerinde çalışır: loop aygıtı, mount ya da ek yetki gerekmez. grub2-mkrescue
# xorriso ister ve araya bir ISO katmanı koyar, o yüzden kullanılmadı.
# Firmware FAT imajını açamazsa QEMU'nun klasörden ürettiği sanal FAT disk (vvfat) denenir.
echo "=== imaj"
mkdir -p "$TMP/esp/EFI/BOOT"
if ! grub2-mkstandalone -O x86_64-efi -d "$MODDIR" -o "$TMP/esp/EFI/BOOT/BOOTX64.EFI" \
        "boot/grub/grub.cfg=$CFG" "boot/grub/themes/vabu=$TEMA" >"$OUT/grub-imaj.log" 2>&1; then
    cat "$OUT/grub-imaj.log"
    atla "grub2-mkstandalone başarısız"
fi
echo "BOOTX64.EFI: $(du -h "$TMP/esp/EFI/BOOT/BOOTX64.EFI" | cut -f1)"
diskler=()
export MTOOLS_SKIP_CHECK=1
truncate -s 64M "$TMP/esp.img"      # 64 silindir x 64 kafa x 32 sektör
if { mformat -i "$TMP/esp.img" -t 64 -h 64 -s 32 :: &&
     mcopy -s -i "$TMP/esp.img" "$TMP/esp/EFI" ::/; } >>"$OUT/grub-imaj.log" 2>&1; then
    diskler+=("format=raw,file=$TMP/esp.img")
else
    tail -n 5 "$OUT/grub-imaj.log"
    echo "FAT imajı oluşturulamadı, yalnızca vvfat denenecek"
fi
diskler+=("format=raw,readonly=on,file=fat:$TMP/esp")

# QMP: tek komut gönderir, yanıtı bekler. Araya giren olay satırları atlanır.
qmp() {
    python3 - "$SOCK" "$@" <<'PY'
import json, socket, sys

s = socket.socket(socket.AF_UNIX)
s.settimeout(20)
s.connect(sys.argv[1])
f = s.makefile("rw")

def gonder(komut, arg=None):
    istek = {"execute": komut}
    if arg:
        istek["arguments"] = arg
    f.write(json.dumps(istek) + "\n")
    f.flush()
    while True:
        satir = f.readline()
        if not satir:
            sys.exit("QMP bağlantısı kapandı")
        yanit = json.loads(satir)
        if "error" in yanit:
            sys.exit("QMP: %s: %s" % (komut, yanit["error"].get("desc")))
        if "return" in yanit:
            return yanit["return"]

json.loads(f.readline())    # karşılama satırı
gonder("qmp_capabilities")
print(json.dumps(gonder(sys.argv[2], json.loads(sys.argv[3]) if len(sys.argv) > 3 else None)))
PY
}
tus() {
    qmp send-key "{\"keys\":[{\"type\":\"qcode\",\"data\":\"$1\"}]}" >/dev/null || echo "tuş gönderilemedi: $1"
}

# Ekranı $TMP/kare.ppm dosyasına alır, "genişlik yükseklik doluluk" yazar.
# Doluluk, sıfır olmayan baytların yüzdesidir: firmware ekranı ve temasız metin menüsü
# neredeyse tümüyle siyahtır, temalı menüde ise arka plan görseli ekranı kaplar.
kare() {
    rm -f "$TMP/kare.ppm"
    qmp screendump "{\"filename\":\"$TMP/kare.ppm\"}" >/dev/null 2>>"$OUT/grub-qemu.log" || return 1
    python3 - "$TMP/kare.ppm" <<'PY'
import sys
d = open(sys.argv[1], "rb").read()
b = d.split(None, 3)        # "P6", genişlik, yükseklik, "255\n" + pikseller
px = b[3][4:]
print(int(b[1]), int(b[2]), 100 - 100 * px.count(0) // max(len(px), 1))
PY
}
goruntu() {
    local gw gh gd
    if read -r gw gh gd < <(kare) && magick "$TMP/kare.ppm" "$OUT/$1.png" 2>>"$OUT/grub-qemu.log"; then
        echo "$1.png: ${gw}x${gh}, doluluk %${gd}"
    else
        echo "::warning::görüntü alınamadı: $1"
    fi
}
kayitlar() {
    echo "=== QEMU kaydı"
    tail -n 20 "$OUT/grub-qemu.log" 2>/dev/null
    echo "=== seri kayıt (OVMF ve GRUB)"
    sed 's/\x1b\[[0-9;?=]*[A-Za-z]//g' "$OUT/grub-seri.log" 2>/dev/null |
        tr -d '\000-\010\013-\037' | grep -av '^[[:space:]]*$' | tail -n 60
    echo "=== OVMF hata ayıklama kaydı (son satırlar)"
    tail -n 15 "$OUT/grub-ovmf.log" 2>/dev/null
}

# q35 + OVMF, yazılım öykünmesi (TCG), ağ yok. İmaj virtio diskten açılır.
# OVMF'nin kendi kaydı 0x402 portundan grub-ovmf.log dosyasına yazılır.
#   qemu_baslat <ekran kartı> <disk>
qemu_baslat() {
    local son
    qemu_durdur
    rm -f "$SOCK"
    cp "$OVMF_VARS" "$TMP/vars"
    : > "$OUT/grub-qemu.log"; : > "$OUT/grub-seri.log"; : > "$OUT/grub-ovmf.log"
    echo "disk: $2" >> "$OUT/grub-qemu.log"
    qemu-system-x86_64 -machine q35 -accel tcg -m 1024 \
        -nodefaults -nic none -display none \
        -drive "if=pflash,unit=0,format=$BICIM,readonly=on,file=$OVMF_CODE" \
        -drive "if=pflash,unit=1,format=$BICIM,file=$TMP/vars" \
        -drive "if=none,id=esp,$2" \
        -device virtio-blk-pci,drive=esp,bootindex=0 \
        -device "$1" \
        -serial "file:$OUT/grub-seri.log" \
        -debugcon "file:$OUT/grub-ovmf.log" -global isa-debugcon.iobase=0x402 \
        -qmp "unix:$SOCK,server=on,wait=off" >>"$OUT/grub-qemu.log" 2>&1 &
    QEMU_PID=$!
    son=$((SECONDS + 15))
    while (( SECONDS < son )); do
        qmp query-status >/dev/null 2>&1 && return 0
        kill -0 "$QEMU_PID" 2>/dev/null || return 1
        sleep 0.3
    done
    return 1
}

# Ekran kartı: standart VGA. OVMF bu kartta 1920x1080 kipini sunar, xres/yres onu EDID
# üzerinden tercih edilen kip de yapar. Bu seçenekleri tanımayan bir QEMU için sade
# kartlar da denenir. GRUB 1920x1080 bulamazsa "auto"ya düşer, test yine sürer.
echo "=== QEMU"
KART=""
for kart in "VGA,edid=on,vgamem_mb=32,xres=1920,yres=1080" "VGA" "bochs-display"; do
    echo "ekran kartı: $kart"
    if qemu_baslat "$kart" "${diskler[0]}"; then KART="$kart"; break; fi
    tail -n 5 "$OUT/grub-qemu.log"
done
[[ -n "$KART" ]] || atla "QEMU başlatılamadı"

# TCG yavaş: menü çizilene kadar ekran aralıklarla yoklanır
echo "menü bekleniyor (en çok $BEKLEME sn): ${diskler[0]}"
hazir=0; disk=0; w=""; h=""; dolu=""; onceki=""
bitis=$((SECONDS + BEKLEME))
while (( SECONDS < bitis )); do
    kill -0 "$QEMU_PID" 2>/dev/null || break
    read -r w h dolu < <(kare)
    simdi="${w:-?}x${h:-?}, doluluk %${dolu:-?}"
    [[ "$simdi" == "$onceki" ]] || echo "  ${SECONDS}. sn: $simdi"
    onceki="$simdi"
    if (( ${dolu:-0} >= 50 )); then hazir=1; break; fi
    if (( disk + 1 < ${#diskler[@]} )) && ! grep -aq "VABU_GRUB" "$OUT/grub-seri.log" &&
       grep -aqsE "BdsDxe: failed to load|No bootable option" "$OUT/grub-seri.log" "$OUT/grub-ovmf.log"; then
        echo "firmware diski açamadı:"
        grep -ahE "BdsDxe: (loading|failed)|No bootable" "$OUT/grub-seri.log" "$OUT/grub-ovmf.log" | tail -n 4
        cp "$OUT/grub-seri.log" "$OUT/grub-seri-$disk.log"
        disk=$((disk + 1))
        echo "sıradaki disk deneniyor: ${diskler[disk]}"
        qemu_baslat "$KART" "${diskler[disk]}" || break
        onceki=""
    fi
    sleep 2
done
if ! kill -0 "$QEMU_PID" 2>/dev/null; then
    kayitlar
    atla "QEMU beklenmedik biçimde kapandı"
fi
if (( hazir )); then
    echo "menü ${SECONDS}. saniyede göründü (${w}x${h})"
    [[ "${w}x${h}" == 1920x1080 ]] || echo "not: 1920x1080 kipi alınamadı (kipler: grub-seri.log)"
    sleep 5
else
    neden="GRUB'a ulaşılamadı"
    grep -aq "VABU_GRUB" "$OUT/grub-seri.log" 2>/dev/null && neden="GRUB açıldı ama temalı menü çizilmedi"
    echo "::warning::$BEKLEME saniyede $neden; ekran yine de kaydediliyor"
    kayitlar
fi

# İlk giriş seçili ve geri sayım görünür; sonra ikinci giriş; sonra komut satırı
goruntu 60-grub
tus down; sleep 2
goruntu 61-grub-ikinci
tus c; sleep 3
goruntu 62-grub-komut
qmp quit >/dev/null 2>&1 && sleep 1

echo "=== görüntüler"
ls -la "$OUT"/6[0-2]-grub*.png 2>/dev/null || echo "::warning::önyükleme menüsünün görüntüsü yok"
exit "$durum"

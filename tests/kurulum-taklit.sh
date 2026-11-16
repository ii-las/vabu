#!/usr/bin/env bash
# Kurulum arka ucunun (install-system) taklidi: tests/ekran.sh kullanır, hiçbir şeye dokunmaz.
#   kurulum-taklit.sh --disks       sahte diskler
#   kurulum-taklit.sh [--dry-run]   ayarları stdin'den okur, adımları yazar
# Yanında "hata" dosyası varsa kurulum yarıda hata verir. Gelen ayarlar (şifrelerin
# yalnızca uzunluğu) yanına girdi.json olarak yazılır.
dir="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" == "--disks" ]]; then
    cat <<'JSON'
[{"path":"/dev/nvme0n1","size":1000204886016,"model":"Samsung SSD 980 PRO","transport":"nvme","removable":false,"tooSmall":false},
 {"path":"/dev/sda","size":61530439680,"model":"SanDisk Ultra","transport":"usb","removable":true,"tooSmall":false},
 {"path":"/dev/vdb","size":8589934592,"model":"","transport":"virtio","removable":false,"tooSmall":true}]
JSON
    exit 0
fi

girdi="$(cat)"
printf '%s\n' "$*" > "$dir/argumanlar"
jq '.password |= length | .passphrase |= length' <<<"$girdi" > "$dir/girdi.json" 2>"$dir/girdi.hata" \
    || echo "{}" > "$dir/girdi.json"

adim() { echo "STEP $1 $2"; }
yuzde() { for p in "$@"; do echo "PROGRESS $p"; sleep 0.5; done; }

adim disk "Disk hazırlanıyor";        yuzde 2 5 8
adim copy "Sistem kopyalanıyor";      yuzde 15 30 45 62
if [[ -e "$dir/hata" ]]; then
    echo "bölümleme aracı: /dev/nvme0n1 kullanımda" >&2
    echo "ERROR /dev/nvme0n1 bölümlenemedi: aygıt kullanımda"
    exit 1
fi
# Görüntü alınabilsin diye kopyalamada biraz bekler
sleep "${VABU_TAKLIT_BEKLE:-9}"
yuzde 74 82
adim system "Sistem ayarlanıyor";     yuzde 88 92
adim boot "Önyükleyici kuruluyor";    yuzde 96
adim finish "Son dokunuşlar";         yuzde 99 100
echo DONE

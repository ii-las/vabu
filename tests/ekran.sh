#!/usr/bin/env bash
# Vabu Shell'i başsız bir Wayland oturumunda (sway, yazılım çizimi) çalıştırır,
# her ekranın görüntüsünü alır ve kabuk kaydındaki QML hatalarını denetler.
#
#   tests/ekran.sh [çıktı klasörü]
#
# Vabu paketleri kurulu bir Fedora'da çalışır (CI bunu her derlemede yapar).
# Gerekenler: sway grim wtype mesa-dri-drivers dbus-daemon libnotify
set -uo pipefail
# This script starts sessions and contains installer UI fixtures. Never run on a host.
[[ "${VABU_TEST_ISOLATED:-}" == 1 ]] || { echo "Yalnızca ayrılmış CI/test ortamında çalışır." >&2; exit 2; }

OUT="${1:-/tmp/ekran}"
SHELL_DIR=/usr/share/vabu/shell
mkdir -p "$OUT"
rm -f "$OUT/test-failed"

if [[ -z "${VABU_EKRAN_ICERIDE:-}" ]]; then
    export VABU_EKRAN_ICERIDE=1
    exec dbus-run-session -- "$0" "$@"
fi

export XDG_RUNTIME_DIR; XDG_RUNTIME_DIR="$(mktemp -d)"; chmod 700 "$XDG_RUNTIME_DIR"
export HOME; HOME="$(mktemp -d)"
export XDG_CONFIG_DIRS=/usr/share/vabu/xdg:/etc/xdg
export WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman
export LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=wayland
export LANG=C.UTF-8 LC_ALL=C.UTF-8
unset WAYLAND_DISPLAY DISPLAY

cat > "$HOME/sway.conf" <<'SWAY'
output HEADLESS-1 resolution 2880x1800 scale 2
output HEADLESS-1 bg #101012 solid_color
default_border none
focus_follows_mouse no
for_window [title="Vabu Ayarlar"] floating enable
SWAY

# Fedora'nın sway'i dosya yetenekleriyle (cap_sys_nice) gelir; yetkisiz bir kapsayıcıda
# böyle bir ikili çalıştırılamaz. Kopyası yetenek taşımaz.
install -m 0755 "$(command -v sway)" "$HOME/sway"
"$HOME/sway" -c "$HOME/sway.conf" >"$OUT/sway.log" 2>&1 &
for _ in $(seq 50); do
    sock="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' | head -1)"
    [[ -n "$sock" ]] && break
    sleep 0.2
done
if [[ -z "${sock:-}" ]]; then
    echo "::error::başsız sway açılamadı"
    cat "$OUT/sway.log"
    exit 1
fi
export WAYLAND_DISPLAY; WAYLAND_DISPLAY="$(basename "$sock")"
export SWAYSOCK; SWAYSOCK="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'sway-ipc.*.sock' | head -1)"

# Ses sunucusu: ses panelleri boş kalmasın (yoksa da test sürer)
(pipewire >/dev/null 2>&1 &) ; sleep 0.5
(wireplumber >/dev/null 2>&1 &)

# Hiçbir adım testi kilitlemesin: her komutun bir süre sınırı var
shot() { sleep "${2:-1.3}"; timeout 20 grim "$OUT/$1.png" 2>>"$OUT/grim.log" || { echo "::error::görüntü alınamadı: $1"; touch "$OUT/test-failed"; }; }
call() { timeout 10 qs -p "$SHELL_DIR" ipc call "$@" >/dev/null 2>&1 || { echo "::error::ipc başarısız: $*"; touch "$OUT/test-failed"; }; }
# Açılan yüzey klavye odağını alsın diye yazmadan önce kısa bir bekleme
yaz() {
    sleep 0.6
    command -v wtype >/dev/null && timeout 5 wtype -s 300 -d 30 "$@" 2>/dev/null || { echo "::error::klavye girdisi gönderilemedi"; echo "keyboard injection failed" >>"$OUT/test-failed"; }
    sleep 0.4
}
assert_open() {
    local target="$1" expected="$2" actual="" attempt
    for attempt in $(seq 20); do
        actual="$(timeout 1 qs -p "$SHELL_DIR" ipc call "$target" isOpen 2>/dev/null)"
        [[ "$actual" == "$expected" ]] && return 0
        sleep 0.1
    done
    printf '::error::%s open state: expected=%s actual=%q\n' "$target" "$expected" "$actual"
    printf '%s open state: expected=%s actual=%q\n' "$target" "$expected" "$actual" >>"$OUT/test-failed"
    shot "failed-$target-$expected" 0
    cat "$OUT/shell.log"
    exit 1
}

# Önce bütün dosyaları derle: yükleme hatalarının hepsi tek seferde görünsün
KOPYA="$HOME/kabuk"
cp -r "$SHELL_DIR" "$KOPYA"
cp "$(dirname "$0")/derle.qml" "$KOPYA/derle.qml"
python3 - "$KOPYA" <<'QMLFILES'
import sys
from pathlib import Path
folder = Path(sys.argv[1])
singletons = [p.stem for p in folder.glob('*.qml') if p.read_text().startswith('pragma Singleton')]
main = folder / 'derle.qml'
main.write_text(main.read_text().replace('[] // VABU_SINGLETONS', '[' + ','.join(sorted(singletons)) + ']'))
QMLFILES
VABU_QML_DOSYALARI="$(cd "$KOPYA" && for f in *.qml; do [[ "$f" == derle.qml ]] || grep -q '^pragma Singleton' "$f" || echo "$f"; done | paste -sd, -)" \
    timeout 25 qs -p "$KOPYA/derle.qml" >"$OUT/derle.log" 2>&1 || { cat "$OUT/derle.log"; exit 1; }
grep -Eq 'DERLEME-BITTI [1-9][0-9]* dosya, 0 hatalı' "$OUT/derle.log" || { cat "$OUT/derle.log"; exit 1; }
echo "=== derleme"
sed 's/\x1b\[[0-9;]*m//g' "$OUT/derle.log" | grep -A12 "DERLEME-" || cat "$OUT/derle.log"

# Görünüm: önce açık, sonra koyu. Kabuk ayar dosyasını izler, değişince yeniden boyanır.
gorunum() { mkdir -p "$HOME/.config/vabu"; printf '{"theme":"%s","onboardingDone":true}\n' "$1" > "$HOME/.config/vabu/shell.json"; sleep 1.5; }
gorunum acik

# Başlatıcının "Kur" kipi için uygulama dizini (AppStream kataloglarından)
if [ -x /usr/libexec/vabu/app-index ]; then
    { basla=$SECONDS; timeout 180 /usr/libexec/vabu/app-index; echo "süre: $((SECONDS - basla)) sn"
      f="${XDG_CACHE_HOME:-$HOME/.cache}/vabu/apps.tsv"; wc -l "$f"; grep -i "gimp" "$f" | head -3
      awk -F'\t' '$4 ~ /^\// { n++ } END { print "dosya simgesi olan:", n+0 }' "$f"; } >"$OUT/app-index.log" 2>&1
fi

qs -p "$SHELL_DIR" >"$OUT/shell.log" 2>&1 &
sleep 10
shot 01-masaustu 0
call welcome open;               shot 01b-hosgeldin
call welcome next;               shot 01c-rehber
call welcome close
call clipboard toggle;           shot 01d-pano-kapali
assert_open clipboard true
yaz -k Escape
assert_open clipboard false
shot 01d2-pano-escape 0
call appmenu open foot;          shot 01e-uygulama-menusu
assert_open appmenu true
yaz -k Escape
assert_open appmenu false
shot 01e2-menu-escape 0

call panel toggle control;       shot 02-kontrol
call panel toggle wifi;          shot 03-wifi
call panel toggle bluetooth;     shot 04-bluetooth
call panel toggle sound;         shot 05-ses
call panel toggle calendar;      shot 06-takvim
call panel close;                sleep 0.5

notify-send -a "Güncellemeler" "12 güncelleme hazır" "Yeniden başlatmadan kurulabilir." 2>/dev/null
notify-send -a "Firefox" "İndirme tamamlandı" "vabu-0.1-x86_64.iso" 2>/dev/null
shot 07-bildirim 1.6
call panel toggle notifications; shot 08-bildirimler
call panel close;                sleep 0.5

call launcher open search;       shot 09-baslatici
yaz "fi";                        shot 10-baslatici-arama 0.8
call launcher close;             sleep 0.4
call launcher open command;      shot 11-baslatici-komut
call launcher close;             sleep 0.4
call launcher open install;      yaz "gimp"; shot 12-baslatici-kur 4
call launcher close;             sleep 0.4
call launcher open calc;         yaz "12*8"; shot 13-baslatici-hesap 0.8
call launcher close;             sleep 0.4

call session toggle;             shot 14-oturum
call session toggle;             sleep 0.4
call shortcuts toggle;           shot 15-kisayollar
call shortcuts toggle;           sleep 0.4

# Koyu görünüm
gorunum koyu
shot 17-koyu-masaustu 0.5
call panel toggle control;       shot 18-koyu-kontrol
call panel toggle notifications; shot 19-koyu-bildirimler
call panel close;                sleep 0.5
call launcher open search;       shot 19b-koyu-baslatici
call launcher close;             sleep 0.4
gorunum acik

# Pencerelerle birlikte
(foot -e sh -c 'fastfetch 2>/dev/null; sleep 120' >/dev/null 2>&1 &)
shot 16-terminal 3

# Dar yan panel
printf '{"theme":"acik","sidebarCompact":true,"onboardingDone":true}\n' > "$HOME/.config/vabu/shell.json"
shot 16b-dar-panel 1.8
printf '{"theme":"koyu","sidebarCompact":true,"onboardingDone":true}\n' > "$HOME/.config/vabu/shell.json"
shot 16c-dar-panel-koyu 1.5
gorunum acik

# Ayarlar: her sayfa
(vabu-settings look >"$OUT/settings.log" 2>&1 &)
shot 20-ayarlar-gorunum 5
n=21
for page in display network sound power health desktop notifications backup accessibility devices drivers apps updates keyboard users about; do
    vabu-settings "$page" >/dev/null 2>&1
    shot "$n-ayarlar-$page" 1.5
    n=$((n + 1))
done
gorunum koyu
shot 29b-ayarlar-koyu 1
gorunum acik
# Narrow window + both languages + 150% text and reduced motion/high contrast.
swaymsg output HEADLESS-1 resolution 1920x1280 scale 2 >/dev/null
swaymsg '[title="Vabu Ayarlar"] resize set width 800 height 600'  >/dev/null
swaymsg '[title="Vabu Ayarlar"] move position center' >/dev/null
for language in tr en; do
    for scale in 1 1.5; do
        printf '{"theme":"acik","onboardingDone":true,"language":"%s","textScale":%s,"reducedMotion":true,"highContrast":true}\n' "$language" "$scale" > "$HOME/.config/vabu/shell.json"
        sleep 2
        for page in look display network sound power health desktop notifications backup accessibility devices drivers apps updates keyboard users about; do
            vabu-settings "$page" >/dev/null 2>&1
            sleep 0.7
            audit="$(timeout 10 qs -p "$SHELL_DIR/settings.qml" ipc call settings audit 2>/dev/null)"
            [[ "$audit" == ok ]] || { echo "::error::UI-AUDIT-FAIL $language $scale $page: $audit"; touch "$OUT/test-failed"; }
            shot "narrow-$language-$scale-$page" 0.05
        done
        shot "narrow-$language-$scale" 0.2
    done
done
gorunum acik
swaymsg output HEADLESS-1 resolution 2880x1800 scale 2 >/dev/null
swaymsg '[title="Vabu Ayarlar"] kill' >/dev/null 2>&1
swaymsg '[app_id="foot"] kill' >/dev/null 2>&1
sleep 0.6

# Katman pencereleri ve ayrılmış kenar boşlukları hesap testinin imlecini
# etkilemesin. Kabuk senaryoları bitti; sonraki oturumlar kendi kabuğunu açar.
pkill -x qs; sleep 1

# Gerçek hesap formu: izole, exec adımı olmayan yapılandırmada fare/klavye ve
# parola doğrulaması denenir. Disk modülleri yüklenmez, kurulum başlatılamaz.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
if command -v calamares >/dev/null; then
    timeout 100 python3 -B "$REPO/tests/installer-input.py" "$OUT" || {
        echo "::error::Calamares hesap formu giriş testi başarısız"
        touch "$OUT/test-failed"
    }
fi

# Giriş ekranı (greetd olmadan sadece görünüm)
if [[ -e "$SHELL_DIR/greeter.qml" ]]; then
    qs -p "$SHELL_DIR/greeter.qml" >"$OUT/greeter.log" 2>&1 &
    shot 32-giris 6
    pkill -x qs; sleep 1
fi

# niri içinde: çalışma alanları kartı gerçek pencerelerle
if command -v niri >/dev/null && [[ -x /usr/libexec/vabu/niri-config ]]; then
    /usr/libexec/vabu/niri-config --defaults -o "$HOME/niri.kdl" 2>>"$OUT/niri.log"
    sed -i "s#^spawn-at-startup .*#spawn-at-startup \"sh\" \"-c\" \"qs -p $SHELL_DIR > $OUT/shell-niri.log 2>\&1\"#" "$HOME/niri.kdl"
    # iç içe pencerede de ekranla aynı ölçek
    printf '\noutput "winit" {\n    scale 2\n}\n' >> "$HOME/niri.kdl"
    niri -c "$HOME/niri.kdl" >>"$OUT/niri.log" 2>&1 &
    sleep 14
    export NIRI_SOCKET; NIRI_SOCKET="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'niri.*.sock' | head -1)"
    if [[ -n "$NIRI_SOCKET" ]]; then
        nm() { timeout 10 niri msg action "$@" >/dev/null 2>&1; }
        nm spawn -- foot; sleep 2
        nm spawn -- nautilus; sleep 5
        shot 40-niri-pencereler 1
        nm focus-workspace-down; sleep 0.8
        nm spawn -- foot; sleep 2.5
        shot 41-niri-ikinci-alan 1
        nm toggle-overview
        shot 42-niri-genel-bakis 1.5
    else
        echo "::error::niri iç içe açılamadı"; touch "$OUT/test-failed"
        tail -20 "$OUT/niri.log"
    fi
fi

# Kilit ekranı en sonda: oturum kilitlendikten sonra başka hiçbir şey görünmez.
# Önce boş, sonra yazarken.
pkill -x niri; pkill -x qs; sleep 1
qs -p "$SHELL_DIR" >"$OUT/shell-kilit.log" 2>&1 &
sleep 8
call lock lock;                  shot 30-kilit 2.5
yaz "parola";                    shot 31-kilit-yazarken 1.2
pkill -x qs

# Önyükleme menüsünün parçaları (gözle bakmak için)
if [[ -d /boot/grub2/themes/vabu ]]; then
    mkdir -p "$OUT/grub" && cp /boot/grub2/themes/vabu/* "$OUT/grub/" 2>/dev/null
fi

echo "=== kabuk kaydı"
cat "$OUT/shell.log"
for f in settings greeter shell-niri; do
    [[ -s "$OUT/$f.log" ]] && { echo "=== $f"; cat "$OUT/$f.log"; }
done
ls -la "$OUT"

# Compilation, missing logs and runtime binding/type errors are required gates.
python3 "$(dirname "$0")/qml-check.py" "$OUT"

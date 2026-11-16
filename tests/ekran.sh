#!/usr/bin/env bash
# Vabu Shell'i başsız bir Wayland oturumunda (sway, yazılım çizimi) çalıştırır,
# her ekranın görüntüsünü alır ve kabuk kaydındaki QML hatalarını denetler.
#
#   tests/ekran.sh [çıktı klasörü]
#
# Vabu paketleri kurulu bir Fedora'da çalışır (CI bunu her derlemede yapar).
# Gerekenler: sway grim wtype mesa-dri-drivers dbus-daemon libnotify
set -uo pipefail

OUT="${1:-/tmp/ekran}"
SHELL_DIR=/usr/share/vabu/shell
mkdir -p "$OUT"

if [[ -z "${VABU_EKRAN_ICERIDE:-}" ]]; then
    export VABU_EKRAN_ICERIDE=1
    exec dbus-run-session -- "$0" "$@"
fi

export XDG_RUNTIME_DIR; XDG_RUNTIME_DIR="$(mktemp -d)"; chmod 700 "$XDG_RUNTIME_DIR"
export HOME; HOME="$(mktemp -d)"
export XDG_CONFIG_DIRS=/usr/share/vabu/xdg:/etc/xdg
export WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman
export LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=wayland
unset WAYLAND_DISPLAY DISPLAY

cat > "$HOME/sway.conf" <<'SWAY'
output HEADLESS-1 resolution 2880x1800 scale 2
output HEADLESS-1 bg #101012 solid_color
default_border none
focus_follows_mouse no
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
    echo "::warning::başsız sway açılamadı, görsel test atlandı"
    cat "$OUT/sway.log"
    exit 0
fi
export WAYLAND_DISPLAY; WAYLAND_DISPLAY="$(basename "$sock")"
export SWAYSOCK; SWAYSOCK="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'sway-ipc.*.sock' | head -1)"

# Ses sunucusu: ses panelleri boş kalmasın (yoksa da test sürer)
(pipewire >/dev/null 2>&1 &) ; sleep 0.5
(wireplumber >/dev/null 2>&1 &)

shot() { sleep "${2:-1.3}"; grim "$OUT/$1.png" 2>>"$OUT/grim.log" || echo "görüntü alınamadı: $1"; }
call() { qs -p "$SHELL_DIR" ipc call "$@" >/dev/null 2>&1 || echo "ipc başarısız: $*"; }
yaz()  { command -v wtype >/dev/null && wtype "$@" 2>/dev/null; sleep 0.4; }

qs -p "$SHELL_DIR" >"$OUT/shell.log" 2>&1 &
sleep 10
shot 01-masaustu 0

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

# Pencerelerle birlikte
(foot -e sh -c 'fastfetch 2>/dev/null; sleep 120' >/dev/null 2>&1 &)
shot 16-terminal 3

# Ayarlar: her sayfa
(vabu-settings look >"$OUT/settings.log" 2>&1 &)
shot 20-ayarlar-gorunum 5
n=21
for page in display network sound drivers apps updates keyboard users about; do
    vabu-settings "$page" >/dev/null 2>&1
    shot "$n-ayarlar-$page" 1.5
    n=$((n + 1))
done
swaymsg '[title="Vabu Ayarlar"] kill' >/dev/null 2>&1
swaymsg '[app_id="foot"] kill' >/dev/null 2>&1
sleep 0.6

# Kilit ekranı: önce boş, sonra yazarken
call lock lock;                  shot 30-kilit 2.5
yaz "parola";                    shot 31-kilit-yazarken 1.2

pkill -x qs; sleep 1

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
    niri -c "$HOME/niri.kdl" >>"$OUT/niri.log" 2>&1 &
    sleep 14
    export NIRI_SOCKET; NIRI_SOCKET="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'niri.*.sock' | head -1)"
    if [[ -n "$NIRI_SOCKET" ]]; then
        niri msg action spawn -- foot; sleep 2
        niri msg action spawn -- nautilus; sleep 5
        shot 40-niri-pencereler 1
        niri msg action focus-workspace-down; sleep 0.8
        niri msg action spawn -- foot; sleep 2.5
        shot 41-niri-ikinci-alan 1
        niri msg action toggle-overview
        shot 42-niri-genel-bakis 1.5
    else
        echo "::warning::niri iç içe açılamadı"
        tail -20 "$OUT/niri.log"
    fi
fi

echo "=== kabuk kaydı"
cat "$OUT/shell.log"
for f in settings greeter shell-niri; do
    [[ -s "$OUT/$f.log" ]] && { echo "=== $f"; cat "$OUT/$f.log"; }
done
ls -la "$OUT"

# Yüklenmeyi engelleyen hatalar derlemeyi durdurur; diğerleri uyarı olarak görünür
fatal='Failed to load|is not a type|non-existent property|Cannot assign to|is not installed|unavailable|Unexpected token|Syntax error'
status=0
for f in shell settings greeter shell-niri; do
    [[ -f "$OUT/$f.log" ]] || continue
    if grep -En "$fatal" "$OUT/$f.log"; then
        echo "::error::$f: QML yüklenirken hata"
        status=1
    fi
    if grep -Ec "ReferenceError|TypeError|Unable to assign|Binding loop" "$OUT/$f.log" >/dev/null; then
        echo "::warning::$f: çalışma zamanı uyarıları var (ayrıntı kayıtta)"
        grep -En "ReferenceError|TypeError|Unable to assign|Binding loop" "$OUT/$f.log" | sort | uniq -c | sort -rn | head -40
    fi
done
exit "$status"

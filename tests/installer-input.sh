#!/usr/bin/env bash
# Disposable compositor for the real installer form test. Never use on a host.
set -euo pipefail
[[ "${VABU_TEST_ISOLATED:-}" == 1 && "$(uname -s)" == Linux ]] || exit 2
if [[ "${VABU_INSTALLER_DBUS:-}" != 1 ]]; then
    export VABU_INSTALLER_DBUS=1
    exec dbus-run-session -- bash "$0" "$@"
fi
# Match the packaged branding asset without installing Vabu or touching a host.
repo="$(cd "$(dirname "$0")/.." && pwd)"
install -Dm0644 "$repo/branding/logo.svg" /usr/share/icons/hicolor/scalable/apps/vabu-logo.svg
OUT="${1:-/tmp/installer-input}"
mkdir -p "$OUT"
base="$(mktemp -d)"
export HOME="$base/home" XDG_RUNTIME_DIR="$base/run"
mkdir -m 700 "$HOME" "$XDG_RUNTIME_DIR"
export WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman
export LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=wayland LANG=C.UTF-8 LC_ALL=C.UTF-8
unset DISPLAY WAYLAND_DISPLAY
cat > "$base/sway.conf" <<'SWAY'
output HEADLESS-1 resolution 2880x1800 scale 2
output HEADLESS-1 bg #101012 solid_color
default_border none
focus_follows_mouse no
SWAY
install -m 0755 "$(command -v sway)" "$base/sway"
"$base/sway" -c "$base/sway.conf" >"$OUT/sway.log" 2>&1 &
sway_pid=$!
cleanup() { kill "$sway_pid" 2>/dev/null || true; wait "$sway_pid" 2>/dev/null || true; rm -rf -- "$base"; }
trap cleanup EXIT
for _ in $(seq 50); do
    sock="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' | head -1)"
    [[ -n "$sock" ]] && break
    sleep .2
done
[[ -n "${sock:-}" ]] || { cat "$OUT/sway.log"; exit 1; }
export WAYLAND_DISPLAY="$(basename "$sock")"
export SWAYSOCK="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'sway-ipc.*.sock' | head -1)"
timeout 150 python3 -B "$(dirname "$0")/installer-input.py" "$OUT"

QT_QPA_PLATFORM=offscreen python3 -B "$repo/tests/installer-style.py" "$OUT"
for view in welcomeq finishedq; do
    VABU_TEST_VIEW="$view" timeout 60 python3 -B "$repo/tests/installer-input.py" "$OUT/$view"
done

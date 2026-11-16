pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Ekran parlaklığı (brightnessctl). Masaüstü ekranlarında arka ışık yoksa `available` false kalır.
Singleton {
    id: root

    property bool available: false
    property real value: 1          // 0-1

    function refresh() { read.running = true }
    function set(v) {
        value = Math.max(0.02, Math.min(1, v))
        apply.restart()
    }
    function noteExternal(v) { value = Math.max(0, Math.min(1, v)); available = true }

    Process {
        id: read
        command: ["brightnessctl", "-m", "-c", "backlight"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[0].split(",")
                const pct = parseInt((f[3] ?? "").replace("%", ""))
                root.available = !isNaN(pct)
                if (root.available) root.value = pct / 100
            }
        }
    }
    // Sürüklerken her adımda süreç başlatma
    Timer {
        id: apply
        interval: 40
        onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(root.value * 100) + "%"])
    }
}

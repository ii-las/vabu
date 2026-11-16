pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Gece ışığı: gün batımından gün doğumuna ekranı sıcak tonlara çeker (wlsunset).
Singleton {
    id: root

    readonly property bool isOn: Config.nightLight
    property bool failed: false
    readonly property string label: !isOn ? Lang.t("Kapalı") : failed ? "Bu ekranda yok" : Sun.night ? Lang.t("Açık") : "Gün batımında"

    function toggle() {
        failed = false
        Config.set("nightLight", !isOn)
    }

    Process {
        id: proc
        running: root.isOn && !root.failed
        command: ["wlsunset", "-l", Sun.latitude.toFixed(2), "-L", Sun.longitude.toFixed(2), "-t", "3700", "-T", "6500"]
        property double startedAt: 0
        onStarted: startedAt = Date.now()
        // Hemen kapandıysa ekran sürücüsü renk ayarını desteklemiyordur; ısrar etme
        onExited: { if (root.isOn && Date.now() - startedAt < 3000) root.failed = true }
    }
}

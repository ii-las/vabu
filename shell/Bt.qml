pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth (BlueZ). Cihaz listesi canlıdır; yoklama yoktur.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool isOn: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property var devices: adapter ? adapter.devices.values : []

    // Bağlı olanlar, sonra eşleşmişler, sonra adı olan yakındakiler
    readonly property var sorted: devices.filter(d => d.paired || d.connected || (d.deviceName ?? "") !== "")
        .slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (a.name ?? "").localeCompare(b.name ?? ""))
    readonly property var connected: devices.filter(d => d.connected)

    readonly property string icon: !available || !isOn ? "bluetooth_disabled" : connected.length ? "bluetooth_connected" : "bluetooth"
    readonly property string label: !available ? "Yok" : !isOn ? "Kapalı"
        : connected.length === 1 ? connected[0].name
        : connected.length > 1 ? connected.length + " cihaz" : "Açık"

    function setOn(v) { if (adapter) adapter.enabled = v }
    function setDiscovering(v) { if (adapter && adapter.enabled) adapter.discovering = v }

    function deviceIcon(d) {
        const i = d.icon ?? ""
        if (i.includes("headset") || i.includes("headphone")) return "headphones"
        if (i.includes("audio")) return "speaker"
        if (i.includes("keyboard")) return "keyboard"
        if (i.includes("mouse")) return "mouse"
        if (i.includes("phone")) return "smartphone"
        if (i.includes("gaming")) return "sports_esports"
        if (i.includes("computer")) return "computer"
        return "bluetooth"
    }
    function activate(d) {
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else { d.trusted = true; d.pair() }
    }
}

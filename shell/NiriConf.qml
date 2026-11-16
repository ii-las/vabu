pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var values: ({})
    // ok | manual (dosya elle düzenlenmiş) | invalid | busy
    property string status: "ok"
    property string lastError: ""
    property bool ready: false          // niri.json okundu (ya da yok)

    readonly property string xkbLayout: values.xkbLayout ?? "us,tr"
    readonly property string xkbVariant: values.xkbVariant ?? ""
    readonly property string xkbOptions: values.xkbOptions ?? "grp:alt_shift_toggle"
    readonly property bool naturalScroll: values.naturalScroll ?? true
    readonly property int gaps: values.gaps ?? 12
    readonly property int radius: values.radius ?? 14
    readonly property bool animations: values.animations ?? true
    readonly property var outputs: values.outputs ?? []

    function set(key, value) {
        const v = Object.assign({}, values)
        v[key] = value
        values = v
        file.setText(JSON.stringify(v, null, 2) + "\n")
        debounce.restart()
    }
    function setMany(obj) {
        values = Object.assign({}, values, obj)
        file.setText(JSON.stringify(values, null, 2) + "\n")
        debounce.restart()
    }
    function apply(force) {
        gen.command = force ? ["/usr/libexec/vabu/niri-config", "--force"] : ["/usr/libexec/vabu/niri-config"]
        gen.environment = { "VABU_KOYU": Theme.dark ? "1" : "0", "VABU_VURGU": Config.accentName }
        status = "busy"
        gen.running = true
    }

    Timer { id: debounce; interval: 350; onTriggered: root.apply(false) }

    Process {
        id: gen
        stderr: StdioCollector { id: err }
        onExited: code => {
            root.status = code === 0 ? "ok" : code === 3 ? "manual" : "invalid"
            root.lastError = code === 0 ? "" : err.text.trim()
        }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/vabu/niri.json"
        printErrors: false
        onLoaded: { try { root.values = JSON.parse(text()) } catch (e) { root.values = {} } root.ready = true }
        onLoadFailed: { root.values = {}; root.ready = true }
    }
}

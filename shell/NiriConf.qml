pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var systemKeymap: ({})
    readonly property var values: store.values
    readonly property string storeError: store.error
    readonly property bool canRecover: store.canRecover
    function recover() { store.recover() }
    // ok | manual (dosya elle düzenlenmiş) | invalid | busy
    property string status: "ok"
    property string lastError: ""
    readonly property bool ready: store.ready

    readonly property string xkbLayout: values.xkbLayout ?? (systemKeymap.layout || "us")
    readonly property string xkbVariant: values.xkbVariant ?? (systemKeymap.variant || "")
    readonly property string xkbOptions: values.xkbOptions ?? (systemKeymap.options || "")
    readonly property bool naturalScroll: values.naturalScroll ?? true
    readonly property int gaps: values.gaps ?? 12
    readonly property int radius: values.radius ?? 14
    readonly property bool animations: values.animations ?? true
    readonly property var outputs: values.outputs ?? []

    function set(key, value) {
        const change = {}; change[key] = value === undefined ? null : value
        store.patch(change)
    }
    function setMany(obj) { store.patch(obj) }
    property bool pendingApply: false
    property bool pendingForce: false
    function apply(force) {
        if (gen.running) { pendingApply = true; pendingForce = pendingForce || force; return }
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
            if (root.pendingApply) {
                const force = root.pendingForce
                root.pendingApply = false; root.pendingForce = false
                Qt.callLater(() => root.apply(force))
            }
        }
    }

    Process { running: true; command: ["/usr/libexec/vabu/desktop-tools", "keymap"]; stdout: StdioCollector { onStreamFinished: { try { root.systemKeymap = JSON.parse(text) } catch(e) {} } } }

    JsonStore {
        id: store; document: "niri"
        onCommitted: debounce.restart()
    }
}

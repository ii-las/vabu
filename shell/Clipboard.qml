pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    property var entries: []
    property string socket: ""
    property bool paused: false
    property string error: ""
    property var queue: []
    property int retries: 0
    readonly property bool wanted: Config.clipboardEnabled && !paused && !Ui.locked
    function action(name, id) {
        if (!wanted || !socket || !["copy","clear","delete"].includes(name)) return
        if (queue.length >= 64) { error = "Pano işlemi tamamlanamadı."; return }
        queue = queue.concat([{name:name, id:id || "", socket:socket}])
        pump.restart()
    }
    function next() {
        if (request.running || !queue.length || !wanted) return
        const item = queue[0]; queue = queue.slice(1)
        if (item.socket !== socket) { pump.restart(); return }
        request.command = ["/usr/libexec/vabu/clipboard", item.name, item.socket].concat(item.id ? [item.id] : [])
        request.running = true
    }
    function reconcile() {
        retry.stop()
        retries = 0
        entries = []; socket = ""; queue = []
        if (!wanted) { request.running = false; server.running = false }
        else if (!server.running) retry.start()
    }
    onWantedChanged: reconcile()
    Component.onCompleted: reconcile()
    Timer { id: pump; interval: 0; onTriggered: root.next() }
    Timer { id: retry; interval: 1000; onTriggered: if (root.wanted && !server.running) server.running = true }
    Process {
        id: server
        command: ["/usr/libexec/vabu/clipboard", "serve"]
        stdout: SplitParser {
            onRead: line => {
                if (!root.wanted) return
                try {
                    const data = JSON.parse(line)
                    if (typeof data.socket !== "string" || !/^vabu-clipboard-[a-z0-9_]+$/.test(data.socket) || !Array.isArray(data.entries)) return
                    root.socket = data.socket; root.entries = data.entries; root.error = ""
                } catch(e) {}
            }
        }
        onExited: code => {
            root.entries = []; root.socket = ""; root.queue = []
            if (root.wanted) {
                root.error = "Pano izleyicisi çalıştırılamadı."
                if (root.retries < 3) { retry.interval = 1000 * Math.pow(2, root.retries++); retry.restart() }
            }
        }
    }
    Process {
        id: request
        onExited: code => { if (code !== 0 && root.wanted) root.error = "Pano işlemi tamamlanamadı."; pump.restart() }
    }
}

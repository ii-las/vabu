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
    function action(name, id) {
        if (!socket || Ui.locked) return
        request.command = ["/usr/libexec/vabu/clipboard", name, socket].concat(id ? [id] : [])
        request.running = true
    }
    Connections { target: Ui; function onLockedChanged() { if (Ui.locked) { root.entries = []; root.socket = "" } } }
    Process {
        id: server
        command: ["/usr/libexec/vabu/clipboard", "serve"]
        running: Config.clipboardEnabled && !root.paused && !Ui.locked
        stdout: SplitParser { onRead: line => { if (Ui.locked || root.paused || !Config.clipboardEnabled) return; try { const data = JSON.parse(line); root.socket = data.socket; root.entries = data.entries; root.error = "" } catch(e) {} } }
        onExited: code => { root.entries = []; root.socket = ""; if (code !== 0 && Config.clipboardEnabled && !root.paused && !Ui.locked) root.error = "Pano izleyicisi çalıştırılamadı." }
    }
    Process { id: request; onExited: code => { if (code !== 0) root.error = "Pano işlemi tamamlanamadı." } }
}

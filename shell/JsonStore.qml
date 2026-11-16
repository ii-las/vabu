import QtQuick
import Quickshell
import Quickshell.Io

// Shared by the shell and settings process; helper merges patches under flock.
Scope {
    id: root
    required property string document
    property var values: ({})
    property var queue: []
    property var active: null
    property bool ready: false
    property bool writable: true
    property bool canRecover: false
    property string error: ""
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/vabu"
    signal committed()
    function load() {
        if (!queue.some(item => item.action === "read")) queue = queue.concat([{action:"read"}])
        pump.restart()
    }
    function patch(changes) {
        if (!writable) return
        const last = queue[queue.length - 1]
        if (last && last.action === "patch") queue = queue.slice(0,-1).concat([{action:"patch", changes:Object.assign({},last.changes,changes)}])
        else queue = queue.concat([{action:"patch", changes:changes}])
        pump.restart()
    }
    function recover() { queue = queue.concat([{action:"recover"}]); pump.restart() }
    function next() {
        if (worker.running || active || !queue.length) return
        active = queue[0]; queue = queue.slice(1)
        worker.command = ["/usr/libexec/vabu/config-store", document, active.action]
        deadline.restart()
        worker.running = true
    }
    Component.onCompleted: load()
    Timer { id: pump; interval: 0; onTriggered: root.next() }
    Process {
        id: worker
        stdinEnabled: true
        onStarted: if (root.active.action === "patch") write(JSON.stringify(root.active.changes) + "\n")
        stdout: StdioCollector { id: result }
        onExited: code => {
            deadline.stop()
            if (!root.active) return
            try {
                const reply = JSON.parse(result.text)
                if (reply.values && typeof reply.values === "object" && !Array.isArray(reply.values)) { if (JSON.stringify(root.values) !== JSON.stringify(reply.values)) root.values = reply.values }
                root.error = reply.error || ""
                if (reply.writable !== undefined) root.writable = reply.writable
                root.canRecover = reply.canRecover === true
                if (code === 0 && root.active.action !== "read") root.committed()
            } catch(e) { root.error = "Ayar hizmeti yanıt vermedi." }
            if (!root.ready) watched.reload()
            root.ready = true
            root.active = null
            pump.restart()
        }
    }
    Timer {
        id: deadline; interval: 15000
        onTriggered: {
            if (worker.running) worker.signal(15)
            root.active = null; root.queue = []; root.ready = true; root.writable = false
            root.error = "Ayar hizmeti yanıt vermedi."
        }
    }
    FileView {
        id: watched
        path: root.dir + "/" + root.document + ".json"
        watchChanges: true
        printErrors: false
        onFileChanged: root.load()
    }
    // Also detects a newly created directory or an external atomic replacement.
    Timer { interval: 30000; repeat: true; running: true; onTriggered: if (!worker.running && !root.queue.length) root.load() }
}

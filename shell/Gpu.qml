pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    property bool available: false
    Process {
        running: true
        command: ["switcherooctl", "list"]
        environment: ({ "LC_ALL": "C" })
        stdout: StdioCollector { onStreamFinished: root.available = /Default:\s*no/i.test(text) }
        onExited: code => { if (code !== 0) root.available = false }
    }
}

// Runs inside a copy of the installed shell; generated singleton list is injected by CI.
import QtQuick
import Quickshell
ShellRoot {
    property var checkedSingletons: [] // VABU_SINGLETONS
    Component.onCompleted: {
        const count = checkedSingletons.length
        const files = (Quickshell.env("VABU_QML_DOSYALARI") || "").split(",").filter(f => f)
        let bad = 0
        for (const file of files) {
            const component = Qt.createComponent(file, Component.PreferSynchronous)
            if (component.status !== Component.Ready) {
                bad++
                console.warn("DERLEME-HATASI " + file + "\n" + component.errorString())
            }
        }
        console.warn("DERLEME-BITTI " + (files.length + count) + " dosya, " + bad + " hatalı")
        // Quickshell handles quit(), not QQmlEngine::exit(). The caller rejects
        // any nonzero error count in DERLEME-BITTI even when quit returns zero.
        Qt.callLater(Qt.quit)
    }
}

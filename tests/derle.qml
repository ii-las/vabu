// Kabuktaki her QML dosyasını derler ve hataları tek seferde listeler.
// tests/ekran.sh bunu kabuğun bir kopyasının içine koyup çalıştırır.
import QtQuick
import Quickshell

ShellRoot {
    Component.onCompleted: {
        const files = (Quickshell.env("VABU_QML_DOSYALARI") || "").split(",").filter(f => f)
        let bad = 0
        for (const f of files) {
            const c = Qt.createComponent(f)
            if (c.status === Component.Error) {
                const msg = c.errorString()
                if (msg.includes("is not creatable")) continue      // singleton: derlendi, yeter
                bad++
                console.log("DERLEME-HATASI " + f + "\n" + msg)
            }
        }
        console.log("DERLEME-BITTI " + files.length + " dosya, " + bad + " hatalı")
        Qt.quit()
    }
}

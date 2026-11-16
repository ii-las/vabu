import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Kilit ekranı: ortak görünüm + PAM doğrulaması.
Item {
    id: root
    property bool primary: true
    signal unlocked()
    readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""

    PamContext {
        id: pam
        config: "vabu-lock"
        onPamMessage: {
            if (responseRequired) respond(view.password)
        }
        onCompleted: result => {
            if (result === PamResult.Success) view.leave()
            else view.fail()
        }
    }

    AuthView {
        id: view
        anchors.fill: parent
        primary: root.primary
        users: [{ name: root.userName, full: root.userName }]
        busy: pam.active
        onSubmitted: if (!pam.active) pam.start()
        onFinished: root.unlocked()
    }
}

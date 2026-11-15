import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pam

Item {
    id: root
    property bool primary: true
    signal unlocked()

    property string password: ""
    property bool error: false
    property bool busy: pam.active

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var days: ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
    readonly property var months: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

    PamContext {
        id: pam
        config: "vabu-lock"
        onPamMessage: {
            if (responseRequired) respond(root.password)
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.password = ""
                root.error = false
                root.unlocked()
            } else {
                root.password = ""
                root.error = true
                rings.shakeIt()
                errorReset.restart()
            }
        }
    }
    Timer { id: errorReset; interval: 2500; onTriggered: root.error = false }

    function submit() {
        if (!password || pam.active) return
        pam.start()
    }

    // Zemin: duvar kağıdı + koyulaştırma
    Image {
        anchors.fill: parent
        source: Config.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(14 / 255, 16 / 255, 22 / 255, 0.32) }

    // Saat
    ColumnLayout {
        anchors { left: parent.left; top: parent.top; leftMargin: 56; topMargin: 44 }
        spacing: 2
        Text {
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Theme.paper
            font.family: Theme.serif
            font.pixelSize: 120
            font.letterSpacing: -2
        }
        Text {
            text: root.days[clock.date.getDay()] + ", " + clock.date.getDate() + " " + root.months[clock.date.getMonth()]
            color: "#E4DED6"
            font.family: Theme.serif
            font.italic: true
            font.pixelSize: 30
        }
    }

    // Halkalar + şifre
    ContourRings {
        id: rings
        visible: root.primary
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -50
        count: root.password.length
        error: root.error
        busy: root.busy
    }

    ColumnLayout {
        visible: root.primary
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: rings.bottom
        anchors.topMargin: 14
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitHeight: 32
            implicitWidth: user.implicitWidth + 28
            radius: 16
            color: Theme.accent
            Text {
                id: user
                anchors.centerIn: parent
                text: Quickshell.env("USER")
                color: Theme.accentInk
                font.family: Theme.serif
                font.pixelSize: 20
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.error ? "Şifre hatalı, tekrar dene"
                : root.busy ? "Doğrulanıyor…"
                : root.password.length > 0 ? root.password.length + " karakter" : "Şifreni yaz"
            color: root.error ? Theme.coral : Theme.paper
            font.family: Theme.serif
            font.pixelSize: 30
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "ENTER AÇAR · ESC TEMİZLER"
            color: Theme.soft
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: 1.6
        }
    }

    // Klavye
    Item {
        anchors.fill: parent
        focus: root.primary
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.submit()
            else if (event.key === Qt.Key_Escape) root.password = ""
            else if (event.key === Qt.Key_Backspace) root.password = root.password.slice(0, -1)
            else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
                root.error = false
                root.password += event.text
            }
            event.accepted = true
        }
    }

    // Alt
    Text {
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 56; bottomMargin: 40 }
        text: "VABU"
        color: Qt.rgba(243 / 255, 241 / 255, 236 / 255, 0.6)
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: 2
    }
    RowLayout {
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 48; bottomMargin: 32 }
        spacing: 8
        PillButton { icon: "moon"; label: "Uyku"; onClicked: Ui.run(["systemctl", "suspend"]) }
        PillButton { icon: "power"; label: "Kapat"; onClicked: Ui.run(["systemctl", "poweroff"]) }
    }
}

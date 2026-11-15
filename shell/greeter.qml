//@ pragma UseQApplication
// Vabu giriş ekranı (greetd greeter). Kilit ekranıyla aynı dil: saat, eş yükselti halkaları.
// greetd → /usr/libexec/vabu/greeter → niri (greeter ayarı) → qs -p .../greeter.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    property var users: []          // [{name, full}]
    property int userIndex: 0
    property string password: ""
    property bool error: false
    property bool busy: false
    property int sessionIndex: 0
    readonly property var sessions: [
        { name: "Vabu", sub: "niri masaüstü", cmd: ["niri-session"] },
        { name: "Vabu Oyun", sub: "Steam, tam ekran", cmd: ["/usr/libexec/vabu/gaming-session"] }
    ]
    readonly property var user: users[userIndex] ?? { name: "", full: "" }

    function submit() {
        if (!password || busy || !user.name) return
        busy = true
        error = false
        Greetd.createSession(user.name)
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password)
        }
        function onAuthFailure(message) {
            root.busy = false
            root.error = true
            root.password = ""
            lastUser.setText(root.user.name)
        }
        function onReadyToLaunch() {
            lastUser.setText(root.user.name)
            Greetd.launch(root.sessions[root.sessionIndex].cmd)
        }
        function onLaunched() {
            // Greeter'ın niri'si kapanınca greetd seçilen oturumu başlatır
            Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"])
        }
        function onError(error) {
            root.busy = false
            root.error = true
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "awk -F: '$3>=1000 && $3<60000 {print $1\":\"$5}' /etc/passwd"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.users = text.split("\n").filter(l => l).map(l => {
                    const [name, gecos] = l.split(":")
                    return { name, full: (gecos || "").split(",")[0] || name }
                })
                lastUser.reload()
            }
        }
    }

    FileView {
        id: lastUser
        path: "/var/cache/vabu-greeter/last-user"
        printErrors: false
        onLoaded: {
            const i = root.users.findIndex(u => u.name === text().trim())
            if (i >= 0) root.userIndex = i
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var days: ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
    readonly property var months: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                id: win
                required property var modelData
                screen: modelData
                readonly property bool primary: modelData === Quickshell.screens[0]
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: Theme.night
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                Image {
                    anchors.fill: parent
                    source: "/usr/share/vabu/assets/wallpaper.png"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle { anchors.fill: parent; color: Qt.rgba(14 / 255, 16 / 255, 22 / 255, 0.32) }

                ColumnLayout {
                    anchors { left: parent.left; top: parent.top; leftMargin: 56; topMargin: 44 }
                    spacing: 2
                    Text { text: Qt.formatTime(clock.date, "HH:mm"); color: Theme.paper; font.family: Theme.serif; font.pixelSize: 120; font.letterSpacing: -2 }
                    Text {
                        text: root.days[clock.date.getDay()] + ", " + clock.date.getDate() + " " + root.months[clock.date.getMonth()]
                        color: "#E4DED6"; font.family: Theme.serif; font.italic: true; font.pixelSize: 30
                    }
                }

                ContourRings {
                    id: rings
                    visible: win.primary
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -60
                    count: root.password.length
                    error: root.error
                    busy: root.busy
                    Connections {
                        target: root
                        function onErrorChanged() { if (root.error) rings.shakeIt() }
                    }
                }

                ColumnLayout {
                    visible: win.primary
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: rings.bottom
                    anchors.topMargin: 10
                    spacing: 12

                    // Kullanıcı seçimi: birden fazla kullanıcı varsa ok tuşları ya da tıklama
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        Repeater {
                            model: root.users
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool isOn: root.userIndex === index
                                height: 34
                                width: uname.implicitWidth + 30
                                radius: 17
                                color: isOn ? Theme.sky : Qt.rgba(243 / 255, 241 / 255, 236 / 255, 0.12)
                                Text {
                                    id: uname
                                    anchors.centerIn: parent
                                    text: parent.modelData.full
                                    color: parent.isOn ? Theme.skyInk : Theme.paper
                                    font.family: Theme.serif
                                    font.pixelSize: 20
                                }
                                MouseArea { anchors.fill: parent; onClicked: { root.userIndex = parent.index; root.password = "" } }
                            }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.error ? "Şifre hatalı, tekrar dene" : root.busy ? "Giriş yapılıyor…"
                            : root.password.length > 0 ? root.password.length + " karakter" : "Şifreni yaz"
                        color: root.error ? Theme.coral : Theme.paper
                        font.family: Theme.serif
                        font.pixelSize: 30
                    }
                    // Oturum seçimi
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        Repeater {
                            model: root.sessions
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool isOn: root.sessionIndex === index
                                width: 180; height: 56; radius: 16
                                color: isOn ? Qt.rgba(142 / 255, 240 / 255, 198 / 255, 0.1) : "transparent"
                                border.color: isOn ? Theme.mint : Qt.rgba(1, 1, 1, 0.16)
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 14
                                    spacing: 2
                                    Text { text: parent.parent.modelData.name; color: parent.parent.index === 1 ? Theme.peach : Theme.paper; font.family: Theme.sans; font.pixelSize: 14; font.weight: Font.Medium }
                                    Text { text: parent.parent.modelData.sub; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 10 }
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.sessionIndex = parent.index }
                            }
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    focus: win.primary
                    Keys.onPressed: event => {
                        const n = root.users.length
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.submit()
                        else if (event.key === Qt.Key_Escape) root.password = ""
                        else if (event.key === Qt.Key_Backspace) root.password = root.password.slice(0, -1)
                        else if (event.key === Qt.Key_Tab && n > 1) { root.userIndex = (root.userIndex + 1) % n; root.password = "" }
                        else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
                            root.error = false
                            root.password += event.text
                        }
                        event.accepted = true
                    }
                }

                Text {
                    anchors { left: parent.left; bottom: parent.bottom; leftMargin: 56; bottomMargin: 40 }
                    text: "VABU"
                    color: Qt.rgba(243 / 255, 241 / 255, 236 / 255, 0.6)
                    font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2
                }
                RowLayout {
                    visible: win.primary
                    anchors { right: parent.right; bottom: parent.bottom; rightMargin: 48; bottomMargin: 32 }
                    spacing: 8
                    PillButton { icon: "moon"; label: "Uyku"; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
                    PillButton { icon: "restart"; label: "Yeniden başlat"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                    PillButton { icon: "power"; label: "Kapat"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                }
            }
        }
    }
}

//@ pragma UseQApplication
// Vabu giriş ekranı (greetd greeter). Kilit ekranıyla aynı görünümü kullanır.
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
    property bool busy: false
    signal failed()
    property int sessionIndex: 0
    readonly property var sessions: [
        { name: "Vabu", sub: "niri masaüstü", cmd: ["niri-session"] },
        { name: "Vabu Oyun", sub: "Steam, tam ekran", cmd: ["/usr/libexec/vabu/gaming-session"] }
    ]
    readonly property var user: users[userIndex] ?? { name: "", full: "" }

    function submit(pw) {
        if (!pw || busy || !user.name) return
        password = pw
        busy = true
        Greetd.createSession(user.name)
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) Greetd.respond(root.password)
        }
        function onAuthFailure(message) {
            root.busy = false
            root.password = ""
            root.failed()
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
            root.password = ""
            root.failed()
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

                AuthView {
                    id: view
                    anchors.fill: parent
                    primary: win.primary
                    wallpaper: "/usr/share/vabu/assets/wallpaper.jpg"
                    users: root.users
                    userIndex: root.userIndex
                    sessions: root.sessions
                    sessionIndex: root.sessionIndex
                    busy: root.busy
                    restartButton: true
                    pinned: true
                    onSubmitted: pw => root.submit(pw)
                    onUserPicked: i => { root.userIndex = i; view.password = "" }
                    onSessionPicked: i => root.sessionIndex = i
                    Connections {
                        target: root
                        function onFailed() { view.fail() }
                    }
                }
            }
        }
    }
}

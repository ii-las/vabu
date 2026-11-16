import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

// Kilit ve giriş ekranının ortak görünümü. Boştayken yalnızca saat vardır; yazmaya
// başlayınca arka plan bulanır, saat yukarı çekilir ve şifre alanı belirir.
Item {
    id: root

    property bool primary: true                 // şifre alanı yalnızca ana ekranda
    property string wallpaper: Config.wallpaper
    property var users: []                      // [{name, full}]
    property int userIndex: 0
    property var sessions: []                   // [{name, sub}]; boşsa seçici görünmez
    property int sessionIndex: 0
    property bool busy: false
    property bool error: false
    property bool restartButton: false
    property string password: ""
    signal submitted(string password)
    signal userPicked(int index)
    signal sessionPicked(int index)
    signal left()

    readonly property var user: users[userIndex] ?? ({ name: "", full: "" })
    property bool pinned: false                 // şifre alanı hep açık (giriş ekranı)
    property bool wanted: false                 // tıklamayla form istendi
    readonly property bool engaged: primary && (pinned || password.length > 0 || error || busy || wanted)
    property real t: engaged ? 1 : 0
    Behavior on t { NumberAnimation { duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

    function fail() {
        password = ""
        error = true
        shake.restart()
        errorReset.restart()
    }
    // Başarılı: içerik solar, sonra `left` gelir
    function leave() { leaving.start() }
    function mix(a, b) { return a + (b - a) * t }

    Timer { id: errorReset; interval: 2600; onTriggered: root.error = false }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var days: ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"]
    readonly property var months: ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int batteryPct: hasBattery ? Math.round(battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0

    // Zemin
    Rectangle { anchors.fill: parent; color: Theme.night }
    Image {
        id: backdrop
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
        visible: false
    }
    MultiEffect {
        anchors.fill: backdrop
        source: backdrop
        autoPaddingEnabled: false
        blurEnabled: true
        blur: root.t
        blurMax: 56
        scale: 1 + 0.03 * root.t
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(10 / 255, 9 / 255, 13 / 255, root.mix(0.14, 0.46)) }

    MouseArea { anchors.fill: parent; onClicked: { root.wanted = !root.wanted || root.password.length > 0; keys.forceActiveFocus() } }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        // Saat
        Column {
            id: clockBox
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.mix(root.height * 0.27, root.height * 0.105)
            scale: root.mix(1, 0.56)
            transformOrigin: Item.Top
            spacing: 4
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.paper
                font.family: Theme.serif
                font.weight: Font.Light
                font.pixelSize: Math.round(Math.min(190, root.height * 0.19))
                font.letterSpacing: -5
                font.features: ({ "tnum": 1, "lnum": 1 })
                lineHeight: 0.9
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.days[clock.date.getDay()] + ", " + clock.date.getDate() + " " + root.months[clock.date.getMonth()]
                color: Theme.alpha(Theme.paper, 0.86)
                font.family: Theme.sans
                font.pixelSize: 21
                font.weight: Font.Medium
            }
        }

        // Boştayken ipucu
        Text {
            visible: root.primary
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.62
            opacity: (1 - root.t) * 0.7
            text: "Açmak için yazmaya başla"
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: 14
        }

        // Giriş
        Column {
            id: form
            visible: root.primary && root.t > 0.01
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.mix(root.height * 0.5, root.height * 0.4)
            width: 340
            opacity: root.t
            spacing: 14

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 76; height: 76
                radius: 26
                color: Qt.rgba(1, 1, 1, 0.14)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.16)
                Text {
                    anchors.centerIn: parent
                    text: (root.user.full || root.user.name || "?").charAt(0).toUpperCase()
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 30
                    font.weight: Font.Medium
                }
            }

            // Ad; birden fazla kullanıcı varsa oklarla değişir
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                IconButton {
                    visible: root.users.length > 1
                    implicitWidth: 30; implicitHeight: 30
                    icon: "chevron_left"; iconSize: 20; iconColor: Theme.soft
                    tooltip: "Önceki kullanıcı"
                    onClicked: root.userPicked((root.userIndex - 1 + root.users.length) % root.users.length)
                }
                Text {
                    height: 30
                    verticalAlignment: Text.AlignVCenter
                    text: root.user.full || root.user.name
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }
                IconButton {
                    visible: root.users.length > 1
                    implicitWidth: 30; implicitHeight: 30
                    icon: "chevron_right"; iconSize: 20; iconColor: Theme.soft
                    tooltip: "Sonraki kullanıcı"
                    onClicked: root.userPicked((root.userIndex + 1) % root.users.length)
                }
            }

            // Şifre alanı
            Rectangle {
                id: field
                width: parent.width
                height: 54
                radius: 18
                color: Qt.rgba(18 / 255, 17 / 255, 22 / 255, 0.56)
                border.width: 1.5
                border.color: root.error ? Theme.danger
                    : root.password.length > 0 ? Theme.alpha(Theme.paper, 0.6) : Qt.rgba(1, 1, 1, 0.14)
                Behavior on border.color { ColorAnimation { duration: Theme.state } }
                transform: Translate { id: nudge }

                Text {
                    visible: root.password.length === 0
                    x: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.busy ? "Doğrulanıyor" : "Şifre"
                    color: Theme.alpha(Theme.paper, 0.5)
                    font.family: Theme.sans
                    font.pixelSize: 16
                }
                Row {
                    x: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7
                    Repeater {
                        model: Math.min(root.password.length, 22)
                        delegate: Rectangle {
                            width: 8; height: 8; radius: 4
                            color: Theme.paper
                            scale: 0
                            Component.onCompleted: scale = 1
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                        }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 42; height: 42
                    radius: 13
                    color: root.password.length > 0 && !root.busy ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
                    Behavior on color { ColorAnimation { duration: Theme.state } }
                    Icon {
                        visible: !root.busy
                        anchors.centerIn: parent
                        name: "arrow_forward"
                        size: 21
                        weight: 400
                        color: root.password.length > 0 ? Theme.accentInk : Theme.muted
                    }
                    Spinner { visible: root.busy; anchors.centerIn: parent; color: Theme.paper }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.send() }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 18
                text: root.error ? "Şifre hatalı" : ""
                color: Theme.danger
                font.family: Theme.sans
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Segmented {
                visible: root.sessions.length > 1
                anchors.horizontalCenter: parent.horizontalCenter
                options: root.sessions.map(s => s.name)
                currentIndex: root.sessionIndex
                onPicked: i => root.sessionPicked(i)
            }
        }

        // Alt satır: durum ve güç
        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 34
            anchors.bottomMargin: 30
            spacing: 16
            opacity: 0.82
            Row {
                visible: root.hasBattery
                spacing: 5
                Icon { anchors.verticalCenter: parent.verticalCenter; name: "battery_" + Math.max(0, Math.min(6, Math.round(root.batteryPct / 100 * 6))) + "_bar"; size: 19 }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "%" + root.batteryPct; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 13; font.features: ({ "tnum": 1 }) }
            }
            Text {
                visible: Niri.kbShort !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: Niri.kbShort
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
            }
        }
        Row {
            visible: root.primary
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 30
            anchors.bottomMargin: 26
            spacing: 8
            Round { icon: "bedtime"; tooltip: "Uyku"; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
            Round { visible: root.restartButton; icon: "restart_alt"; tooltip: "Yeniden başlat"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
            Round { icon: "power_settings_new"; iconColor: Theme.danger; tooltip: "Kapat"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
        }
    }

    component Round: IconButton {
        implicitWidth: 46; implicitHeight: 46
        radius: 16
        idle: Qt.rgba(18 / 255, 17 / 255, 22 / 255, 0.46)
    }

    function send() {
        if (!password || busy) return
        submitted(password)
    }

    // Klavye
    Item {
        id: keys
        anchors.fill: parent
        focus: root.primary
        Keys.onPressed: event => {
            const n = root.users.length
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.send()
            else if (event.key === Qt.Key_Escape) { root.password = ""; root.wanted = false }
            else if (event.key === Qt.Key_Backspace) root.password = root.password.slice(0, -1)
            else if (event.key === Qt.Key_Tab && n > 1) root.userPicked((root.userIndex + 1) % n)
            else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && !root.busy) {
                root.error = false
                root.password += event.text
            }
            event.accepted = true
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: nudge; property: "x"; to: -12; duration: 55 }
        NumberAnimation { target: nudge; property: "x"; to: 11; duration: 70 }
        NumberAnimation { target: nudge; property: "x"; to: -7; duration: 65 }
        NumberAnimation { target: nudge; property: "x"; to: 4; duration: 60 }
        NumberAnimation { target: nudge; property: "x"; to: 0; duration: 55 }
    }
    SequentialAnimation {
        id: leaving
        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InCubic }
        ScriptAction { script: { root.password = ""; root.left() } }
    }
}

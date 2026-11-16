import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Dar yan panel: aynı kartlar, yalnızca rakam ve simgelerle.
ColumnLayout {
    id: root
    property real originX: 0
    property string screenName: ""
    spacing: 8

    function isOpen(name) { return Ui.popover === name && Ui.popoverScreen === screenName }
    function toggle(name) { Ui.togglePopover(name, screenName) }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int batteryPct: hasBattery ? Math.round(battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0
    readonly property bool charging: hasBattery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge)
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    PwObjectTracker { objects: [root.sink] }

    // Saat: saat üstte, dakika altta
    Card {
        Layout.fillWidth: true
        originX: root.originX
        implicitHeight: 64
        edgeColor: root.isOpen("calendar") ? Theme.alpha(Theme.accent, 0.6) : Theme.edge

        SystemClock { id: clock; precision: SystemClock.Minutes }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: clockMouse.pressed ? Theme.pressed : clockMouse.containsMouse ? Theme.alpha(Theme.paper, 0.03) : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        Column {
            anchors.centerIn: parent
            spacing: -4
            Repeater {
                model: ["HH", "mm"]
                delegate: Text {
                    required property string modelData
                    required property int index
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, modelData)
                    color: index === 0 ? Theme.paper : Theme.soft
                    font.family: Theme.sans
                    font.pixelSize: 21
                    font.weight: index === 0 ? Font.DemiBold : Font.Medium
                    font.features: ({ "tnum": 1, "lnum": 1 })
                }
            }
        }
        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggle("calendar")
        }
    }

    // Alanlar: sıra numarası, altında pencere sayısı kadar nokta (en çok üç)
    Card {
        id: spaces
        Layout.fillWidth: true
        originX: root.originX
        readonly property var rows: Niri.rowsFor(root.screenName)
        readonly property int activeIndex: rows.findIndex(r => r.ws.is_active)
        visible: Niri.available && rows.length > 0
        implicitHeight: spacesCol.implicitHeight + 12

        Rectangle {
            visible: spaces.activeIndex >= 0
            x: 6
            y: 6 + spaces.activeIndex * 42
            width: parent.width - 12
            height: 40
            radius: Theme.radiusRow
            color: Theme.accent
            Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        }

        Column {
            id: spacesCol
            x: 6
            y: 6
            width: parent.width - 12
            spacing: 2
            Repeater {
                model: spaces.rows.length
                delegate: Item {
                    id: cell
                    required property int index
                    readonly property var r: spaces.rows[index] ?? ({ ws: {}, columns: [], count: 0, spare: false })
                    readonly property bool isOn: r.ws.is_active === true
                    width: spacesCol.width
                    height: 40
                    Accessible.role: Accessible.Button
                    Accessible.name: "Alan " + (r.ws.idx ?? "")

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusRow
                        visible: !cell.isOn
                        color: cellMouse.pressed ? Theme.pressed : cellMouse.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }
                    Icon {
                        visible: cell.r.spare && !cell.isOn
                        anchors.centerIn: parent
                        name: "add"
                        size: 17
                        color: Theme.faint
                    }
                    Text {
                        visible: !cell.r.spare || cell.isOn
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: cell.r.count > 0 ? -4 : 0
                        text: cell.r.ws.idx ?? ""
                        color: cell.isOn ? Theme.accentInk : Theme.paper
                        font.family: Theme.sans
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.features: ({ "tnum": 1 })
                        Behavior on color { ColorAnimation { duration: Theme.state } }
                    }
                    Row {
                        visible: cell.r.count > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 7
                        spacing: 3
                        Repeater {
                            model: Math.min(3, cell.r.count)
                            delegate: Rectangle {
                                width: 4; height: 4; radius: 2
                                color: cell.isOn ? Theme.accentInk : Theme.soft
                                opacity: 0.85
                            }
                        }
                    }
                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Niri.focusWorkspace(cell.r.ws)
                    }
                }
            }
        }

        WheelHandler {
            property double last: 0
            onWheel: event => {
                const now = Date.now()
                if (now - last < 160) return
                last = now
                Niri.action([event.angleDelta.y > 0 ? "focus-workspace-up" : "focus-workspace-down"])
            }
        }
    }

    // Ara ve sabitlenenler
    Card {
        Layout.fillWidth: true
        originX: root.originX
        implicitHeight: appsCol.implicitHeight + 12

        Column {
            id: appsCol
            x: 6
            y: 6
            width: parent.width - 12
            spacing: 2

            IconButton {
                width: parent.width
                icon: "search"
                iconColor: Theme.soft
                idle: Theme.well
                tooltip: "Ara"
                onClicked: Ui.openLauncher("search")
            }
            Repeater {
                model: Apps.pinnedEntries.slice(0, 6)
                delegate: Item {
                    id: app
                    required property var modelData
                    readonly property bool isRunning: Apps.windowsOf(modelData).length > 0
                    width: appsCol.width
                    height: 42
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 12
                        color: appMouse.pressed ? Theme.pressed : appMouse.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 26
                        source: Quickshell.iconPath(app.modelData.icon, "application-x-executable")
                        scale: appMouse.pressed ? 0.88 : appMouse.containsMouse ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                    }
                    // açık: kenarda kısa bir çizgi
                    Rectangle {
                        width: 3
                        height: app.isRunning ? 10 : 0
                        radius: 1.5
                        opacity: app.isRunning ? 1 : 0
                        color: Theme.paper
                        anchors.verticalCenter: parent.verticalCenter
                        x: Config.sidebarSide === "right" ? parent.width - 2 : -1
                        Behavior on height { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                        Behavior on opacity { NumberAnimation { duration: Theme.state } }
                    }
                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: e => e.button === Qt.MiddleButton ? Apps.launch(app.modelData) : Apps.open(app.modelData)
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    // Çalan parça: oynat / duraklat
    Card {
        Layout.fillWidth: true
        originX: root.originX
        visible: Config.showMedia && root.player !== null
        implicitHeight: 52
        IconButton {
            anchors.centerIn: parent
            icon: root.player?.isPlaying ? "pause" : "play_arrow"
            filled: true
            tooltip: root.player?.isPlaying ? "Duraklat" : "Oynat"
            onClicked: root.player?.togglePlaying()
        }
    }

    // Durum: alt alta, en altta paneli genişletme düğmesi
    Card {
        Layout.fillWidth: true
        originX: root.originX
        implicitHeight: statusCol.implicitHeight + 12

        Column {
            id: statusCol
            x: 6
            y: 6
            width: parent.width - 12
            spacing: 2

            IconButton {
                width: parent.width
                icon: Net.icon
                iconColor: Net.kind === "none" ? Theme.muted : Theme.paper
                tooltip: "Ağ: " + Net.label
                active: root.isOpen("wifi")
                onClicked: root.toggle("wifi")
            }
            IconButton {
                visible: Bt.available
                width: parent.width
                icon: Bt.icon
                iconColor: Bt.isOn ? Theme.paper : Theme.muted
                tooltip: "Bluetooth: " + Bt.label
                active: root.isOpen("bluetooth")
                onClicked: root.toggle("bluetooth")
            }
            IconButton {
                width: parent.width
                icon: root.muted || root.volume === 0 ? "volume_off" : root.volume < 0.4 ? "volume_down" : "volume_up"
                iconColor: root.muted ? Theme.muted : Theme.paper
                tooltip: root.muted ? "Ses kapalı" : "Ses %" + Math.round(root.volume * 100)
                active: root.isOpen("sound")
                onClicked: root.toggle("sound")
                WheelHandler {
                    onWheel: event => {
                        if (!root.sink?.audio) return
                        const step = event.angleDelta.y > 0 ? 0.05 : -0.05
                        root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
                    }
                }
            }
            IconButton {
                id: bell
                width: parent.width
                icon: Notifs.dnd ? "notifications_off" : "notifications"
                iconColor: Notifs.dnd ? Theme.muted : Theme.paper
                tooltip: "Bildirimler: " + Notifs.count
                active: root.isOpen("notifications")
                onClicked: root.toggle("notifications")
                Rectangle {
                    visible: Notifs.count > 0 && !bell.active
                    width: 7; height: 7; radius: 3.5
                    x: parent.width / 2 + 5
                    y: 9
                    color: Theme.ok
                }
            }
            IconButton {
                width: parent.width
                icon: root.hasBattery ? (root.charging ? "bolt" : root.batteryPct >= 95 ? "battery_full"
                    : "battery_" + Math.max(0, Math.min(6, Math.round(root.batteryPct / 100 * 6))) + "_bar") : "tune"
                iconColor: root.hasBattery && !root.charging && root.batteryPct <= 15 ? Theme.danger : Theme.paper
                tooltip: root.hasBattery ? "Kontrol merkezi · pil %" + root.batteryPct : "Kontrol merkezi"
                active: root.isOpen("control")
                onClicked: root.toggle("control")
            }
            Rectangle {
                width: parent.width - 16
                x: 8
                height: 1
                color: Theme.line
            }
            IconButton {
                width: parent.width
                icon: Config.sidebarSide === "right" ? "right_panel_open" : "left_panel_open"
                iconColor: Theme.soft
                tooltip: "Yan paneli genişlet"
                onClicked: { Ui.closePopover(); Config.set("sidebarCompact", false) }
            }
        }
    }
}

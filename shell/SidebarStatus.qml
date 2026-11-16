import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Durum satırı. Her düğme kendi panelini yan panelin hemen yanında açar.
Card {
    id: root
    property string screenName: ""
    implicitHeight: 54

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    // Quickshell sürümüne göre yüzde 0–1 ya da 0–100 gelebilir
    readonly property int batteryPct: hasBattery ? Math.round(battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0
    readonly property bool charging: hasBattery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge)
    readonly property string batteryIcon: batteryPct >= 95 ? "battery_full" : "battery_" + Math.max(0, Math.min(6, Math.round(batteryPct / 100 * 6))) + "_bar"

    PwObjectTracker { objects: [root.sink] }

    function isOpen(name) { return Ui.popover === name && Ui.popoverScreen === screenName }
    function toggle(name) { Ui.togglePopover(name, screenName) }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 2

        IconButton {
            icon: Net.icon
            iconColor: Net.kind === "none" ? Theme.muted : Theme.paper
            tooltip: "Ağ: " + Net.label
            active: root.isOpen("wifi")
            onClicked: root.toggle("wifi")
        }
        IconButton {
            visible: Bt.available
            icon: Bt.icon
            iconColor: Bt.isOn ? Theme.paper : Theme.muted
            tooltip: "Bluetooth: " + Bt.label
            active: root.isOpen("bluetooth")
            onClicked: root.toggle("bluetooth")
        }
        IconButton {
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
            icon: Notifs.dnd ? "notifications_off" : "notifications"
            iconColor: Notifs.dnd ? Theme.muted : Theme.paper
            tooltip: "Bildirimler: " + Notifs.count
            active: root.isOpen("notifications")
            onClicked: root.toggle("notifications")
            Rectangle {
                visible: Notifs.count > 0 && !bell.active
                width: 7; height: 7; radius: 3.5
                x: parent.width - 13
                y: 9
                color: Theme.ok
            }
        }

        Item { Layout.fillWidth: true }

        // Pil: yalnızca dizüstünde
        Item {
            visible: root.hasBattery
            implicitWidth: batt.implicitWidth + 12
            implicitHeight: 40
            Row {
                id: batt
                anchors.centerIn: parent
                spacing: 3
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.charging ? "bolt" : root.batteryIcon
                    size: 19
                    filled: root.charging
                    color: !root.charging && root.batteryPct <= 15 ? Theme.danger : Theme.paper
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.batteryPct
                    color: !root.charging && root.batteryPct <= 15 ? Theme.danger : Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.features: ({ "tnum": 1 })
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggle("control") }
        }

        IconButton {
            icon: "tune"
            tooltip: "Kontrol merkezi"
            active: root.isOpen("control")
            onClicked: root.toggle("control")
        }
    }
}

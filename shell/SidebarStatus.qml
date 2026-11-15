import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Card {
    id: root
    implicitHeight: 52
    radius: 18

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    // Quickshell sürümüne göre yüzde 0–1 ya da 0–100 gelebilir
    readonly property int batteryPct: hasBattery ? Math.round(battery.percentage > 1 ? battery.percentage : battery.percentage * 100) : 0

    property string netKind: "none"   // wifi | ethernet | none
    property string netName: ""

    PwObjectTracker { objects: [root.sink] }

    Process {
        id: nm
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let kind = "none", name = ""
                for (const l of text.split("\n")) {
                    const [type, state, conn] = l.split(":")
                    if (state !== "connected") continue
                    if (type === "ethernet") { kind = "ethernet"; name = conn; break }
                    if (type === "wifi") { kind = "wifi"; name = conn }
                }
                root.netKind = kind
                root.netName = name
            }
        }
    }
    Timer { interval: 8000; running: true; repeat: true; triggeredOnStart: true; onTriggered: nm.running = true }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 0

        IconButton {
            icon: root.netKind === "ethernet" ? "ethernet" : root.netKind === "wifi" ? "wifi" : "wifi-off"
            iconColor: root.netKind === "none" ? Theme.faint : Theme.paper
            tooltip: root.netKind === "none" ? "Ağ bağlı değil" : "Ağ: " + root.netName
            onClicked: Ui.settings("network")
        }

        IconButton {
            icon: root.muted || root.volume === 0 ? "mute" : root.volume < 0.4 ? "volume-low" : "volume"
            tooltip: root.muted ? "Ses kapalı" : "Ses %" + Math.round(root.volume * 100)
            onClicked: if (root.sink) root.sink.audio.muted = !root.sink.audio.muted
            WheelHandler {
                onWheel: event => {
                    if (!root.sink) return
                    const step = event.angleDelta.y > 0 ? 0.05 : -0.05
                    root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 40
            visible: root.hasBattery
            Row {
                anchors.centerIn: parent
                spacing: 6
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22; height: 12; radius: 3.5
                    color: "transparent"
                    border.color: Theme.paper
                    border.width: 1.5
                    Rectangle {
                        x: 2.5; y: 2.5
                        height: parent.height - 5
                        width: (parent.width - 5) * root.batteryPct / 100
                        radius: 1.5
                        color: root.batteryPct <= 15 ? Theme.coral : Theme.paper
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.batteryPct
                    color: Theme.paper
                    font.family: Theme.mono
                    font.pixelSize: 12
                }
            }
        }
        Item { Layout.fillWidth: true; visible: !root.hasBattery }

        IconButton { icon: "sliders"; tooltip: "Ayarlar"; onClicked: Ui.settings() }
        IconButton { icon: "power"; iconColor: Theme.coral; tooltip: "Oturum menüsü"; onClicked: Ui.sessionMenuOpen = true }
    }
}

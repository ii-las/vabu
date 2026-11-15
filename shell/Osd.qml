import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: root
    color: "transparent"
    anchors { bottom: true }
    margins { bottom: 64 }
    implicitWidth: 320
    implicitHeight: 64
    exclusionMode: ExclusionMode.Ignore
    visible: shown
    WlrLayershell.namespace: "vabu-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    property bool shown: false
    property bool ready: false          // oturum açılışındaki ilk değerlerde gösterme
    Timer { running: true; interval: 3000; onTriggered: root.ready = true }
    property string kind: "volume"   // volume | brightness
    property real value: 0
    property bool muted: false

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    function show(k, v, m) {
        if (!ready) return
        kind = k
        value = Math.max(0, Math.min(1, v))
        muted = !!m
        shown = true
        hide.restart()
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.show("volume", root.sink.audio.volume, root.sink.audio.muted) }
        function onMutedChanged() { root.show("volume", root.sink.audio.volume, root.sink.audio.muted) }
    }

    Timer { id: hide; interval: 1500; onTriggered: root.shown = false }

    Card {
        anchors.fill: parent
        strong: true
        radius: 32

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            spacing: 14
            Icon {
                name: root.kind === "brightness" ? "sun" : (root.muted || root.value === 0 ? "mute" : root.value < 0.4 ? "volume-low" : "volume")
                size: 20
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 8
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.14)
                Rectangle {
                    width: parent.width * (root.muted ? 0 : root.value)
                    height: parent.height
                    radius: 4
                    color: root.kind === "brightness" ? Theme.peach : Theme.accent
                    Behavior on width { NumberAnimation { duration: Theme.fast } }
                }
            }
            Text {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: root.muted ? "-" : Math.round(root.value * 100)
                color: Theme.paper
                font.family: Theme.mono
                font.pixelSize: 13
            }
        }
    }
}

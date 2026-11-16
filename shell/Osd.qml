import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Ses ve parlaklık göstergesi: ekranın altında kısa süre belirir.
PanelWindow {
    id: root
    color: "transparent"
    anchors { bottom: true }
    margins { bottom: 56 }
    implicitWidth: 300 + 2 * pad
    implicitHeight: 52 + 2 * pad
    exclusionMode: ExclusionMode.Ignore
    visible: showing || shown > 0.001
    mask: Region {}
    WlrLayershell.namespace: "vabu-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property int pad: 40                // gölge payı
    property bool showing: false
    property real shown: showing ? 1 : 0
    Behavior on shown {
        NumberAnimation {
            duration: root.showing ? 260 : Theme.exit
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.showing ? Theme.emphasized : Theme.accelerate
        }
    }

    property bool ready: false          // oturum açılışındaki ilk değerlerde gösterme
    Timer { running: true; interval: 3000; onTriggered: root.ready = true }
    property string kind: "volume"      // volume | brightness
    property real value: 0
    property bool muted: false

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.sink] }

    function show(k, v, m) {
        if (!ready) return
        // ses paneli ya da kontrol merkezi açıkken kaydırıcı zaten görünüyor
        if (Ui.popover === "sound" || Ui.popover === "control") return
        kind = k
        value = Math.max(0, Math.min(1, v))
        muted = !!m
        showing = true
        hide.restart()
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.show("volume", root.sink.audio.volume, root.sink.audio.muted) }
        function onMutedChanged() { root.show("volume", root.sink.audio.volume, root.sink.audio.muted) }
    }

    Timer { id: hide; interval: 1400; onTriggered: root.showing = false }

    Card {
        x: root.pad
        y: root.pad
        width: 300
        height: 52
        radius: 26
        tint: Theme.panelDeep
        shadow: true
        originX: ((root.screen?.width ?? 0) - root.width) / 2
        originY: (root.screen?.height ?? 0) - 56 - root.height

        opacity: root.shown
        transform: [
            Scale { origin.x: 150; origin.y: 52; xScale: 0.92 + 0.08 * root.shown; yScale: 0.92 + 0.08 * root.shown },
            Translate { y: 12 * (1 - root.shown) }
        ]

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 20
            spacing: 14
            Icon {
                name: root.kind === "brightness" ? "light_mode" : (root.muted || root.value === 0 ? "volume_off" : root.value < 0.4 ? "volume_down" : "volume_up")
                size: 21
                color: root.muted ? Theme.muted : Theme.paper
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.14)
                Rectangle {
                    width: parent.width * (root.muted ? 0 : root.value)
                    height: parent.height
                    radius: 2
                    color: Theme.paper
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }
            }
            Text {
                Layout.preferredWidth: 26
                horizontalAlignment: Text.AlignRight
                text: root.muted ? "0" : Math.round(root.value * 100)
                color: Theme.soft
                font.family: Theme.sans
                font.pixelSize: 13
                font.weight: Font.Medium
                font.features: ({ "tnum": 1 })
            }
        }
    }
}

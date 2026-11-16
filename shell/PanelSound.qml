import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    spacing: 4

    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker { objects: root.sinks.concat(root.sources) }

    function label(n) { return n.description || n.nickname || n.name || "Bilinmeyen aygıt" }
    function sinkIcon(n) {
        const t = ((n.properties || {})["device.form-factor"] || "") + " " + (n.name || "")
        if (/head(phone|set)|bluez/i.test(t)) return "headphones"
        if (/hdmi|displayport/i.test(t)) return "tv"
        return "speaker"
    }

    component Level: Rectangle {
        id: level
        property var node: null
        property string icon: "volume_up"
        property string mutedIcon: "volume_off"
        readonly property real value: node?.audio?.volume ?? 0
        readonly property bool muted: node?.audio?.muted ?? false
        Layout.fillWidth: true
        implicitHeight: 48
        radius: Theme.radiusTile
        color: Theme.well
        opacity: node ? 1 : 0.5

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 14
            spacing: 6
            IconButton {
                implicitWidth: 36; implicitHeight: 36
                icon: level.muted || level.value === 0 ? level.mutedIcon : level.icon
                iconColor: level.muted ? Theme.muted : Theme.paper
                tooltip: level.muted ? "Sesi aç" : "Sessize al"
                onClicked: if (level.node?.audio) level.node.audio.muted = !level.node.audio.muted
            }
            VSlider {
                Layout.fillWidth: true
                value: level.muted ? 0 : level.value
                onMoved: v => { if (level.node?.audio) { level.node.audio.muted = false; level.node.audio.volume = v } }
            }
            Text {
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignRight
                text: level.muted ? "0" : Math.round(level.value * 100)
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 12.5
                font.features: ({ "tnum": 1 })
            }
        }
    }

    PanelHeader { title: "Ses" }

    Level { node: root.sink }
    Repeater {
        model: root.sinks.length > 1 ? root.sinks : []
        delegate: ListRow {
            required property var modelData
            icon: root.sinkIcon(modelData)
            label: root.label(modelData)
            selected: modelData === root.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    Text {
        Layout.leftMargin: 6
        Layout.topMargin: 12
        Layout.bottomMargin: 4
        text: "Mikrofon"
        color: Theme.muted
        font.family: Theme.sans
        font.pixelSize: 12.5
        font.weight: Font.Medium
    }
    Level { node: root.source; icon: "mic"; mutedIcon: "mic_off" }
    Repeater {
        model: root.sources.length > 1 ? root.sources : []
        delegate: ListRow {
            required property var modelData
            icon: "mic"
            label: root.label(modelData)
            selected: modelData === root.source
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }

    DashLine { Layout.fillWidth: true; Layout.topMargin: 8; Layout.bottomMargin: 4 }
    ListRow {
        icon: "settings"
        label: "Ses ayarları"
        iconColor: Theme.soft
        trailing: "chevron_right"
        onClicked: Ui.settings("sound")
    }
}

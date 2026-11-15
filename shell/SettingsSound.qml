import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

ColumnLayout {
    id: page
    spacing: 20

    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var streams: nodes.filter(n => n.audio && n.isStream)
    readonly property var defSink: Pipewire.defaultAudioSink
    readonly property var defSource: Pipewire.defaultAudioSource

    PwObjectTracker { objects: page.sinks.concat(page.sources).concat(page.streams) }

    function label(n) {
        return n.description || n.nickname || n.name || "Bilinmeyen aygıt"
    }
    function appName(n) {
        const p = n.properties || {}
        return p["application.name"] || n.description || n.name || "Uygulama"
    }

    component DeviceList: ColumnLayout {
        id: list
        property string title
        property var devices: []
        property var current: null
        property string kind: "sink"
        Layout.fillWidth: true
        spacing: 0
        SectionLabel { text: list.title }
        DashLine { Layout.fillWidth: true }
        Repeater {
            model: list.devices
            delegate: ColumnLayout {
                id: dev
                required property var modelData
                readonly property bool on: list.current === modelData
                Layout.fillWidth: true
                spacing: 0
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    RowLayout {
                        anchors.fill: parent
                        spacing: 14
                        Rectangle {
                            implicitWidth: 22; implicitHeight: 22; radius: 11
                            color: "transparent"
                            border.width: 2
                            border.color: dev.on ? Theme.accent : Qt.rgba(1, 1, 1, 0.3)
                            Rectangle { anchors.centerIn: parent; visible: dev.on; width: 10; height: 10; radius: 5; color: Theme.accent }
                        }
                        Text { Layout.fillWidth: true; text: page.label(dev.modelData); color: Theme.paper; font.family: Theme.sans; font.pixelSize: 15; elide: Text.ElideRight }
                        Icon {
                            name: dev.modelData.audio.muted ? "mute" : "volume"
                            color: dev.modelData.audio.muted ? Theme.faint : Theme.paper
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dev.modelData.audio.muted = !dev.modelData.audio.muted }
                        }
                        VSlider {
                            implicitWidth: 220
                            value: dev.modelData.audio.volume
                            to: 1
                            onMoved: v => dev.modelData.audio.volume = v
                        }
                        Text {
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                            text: Math.round(dev.modelData.audio.volume * 100)
                            color: Theme.soft; font.family: Theme.mono; font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 320
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (list.kind === "sink") Pipewire.preferredDefaultAudioSink = dev.modelData
                            else Pipewire.preferredDefaultAudioSource = dev.modelData
                        }
                    }
                }
                DashLine { Layout.fillWidth: true }
            }
        }
        Text {
            visible: list.devices.length === 0
            Layout.topMargin: 12
            text: "Aygıt bulunamadı."
            color: Theme.muted; font.family: Theme.serif; font.italic: true; font.pixelSize: 20
        }
    }

    DeviceList { title: "ÇIKIŞ · HOPARLÖR VE KULAKLIK"; devices: page.sinks; current: page.defSink; kind: "sink" }
    DeviceList { title: "GİRİŞ · MİKROFON"; devices: page.sources; current: page.defSource; kind: "source" }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        SectionLabel { text: "UYGULAMALAR" }
        DashLine { Layout.fillWidth: true }
        Repeater {
            model: page.streams
            delegate: SettingRow {
                required property var modelData
                label: page.appName(modelData)
                VSlider { implicitWidth: 220; value: modelData.audio.volume; onMoved: v => modelData.audio.volume = v }
            }
        }
        Text {
            visible: page.streams.length === 0
            Layout.topMargin: 12
            text: "Şu an ses çalan bir uygulama yok."
            color: Theme.muted; font.family: Theme.serif; font.italic: true; font.pixelSize: 20
        }
    }

    PillButton {
        label: "Gelişmiş ses ayarları"
        icon: "sliders"
        onClicked: Quickshell.execDetached(["pavucontrol"])
    }
}

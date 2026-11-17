import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

ColumnLayout {
    id: page
    spacing: 24

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

    // Ses düzeyi satırı: sessize alma düğmesi, kaydırıcı, yüzde
    component Level: RowLayout {
        id: level
        property var node: null
        property string icon: "volume_up"
        property string mutedIcon: "volume_off"
        readonly property bool muted: node?.audio?.muted ?? false
        spacing: 6
        IconButton {
            implicitWidth: 36; implicitHeight: 36
            icon: level.muted ? level.mutedIcon : level.icon
            iconColor: level.muted ? Theme.muted : Theme.paper
            tooltip: level.muted ? "Sesi aç" : "Sessize al"
            onClicked: if (level.node?.audio) level.node.audio.muted = !level.node.audio.muted
        }
        VSlider {
            implicitWidth: 240
            value: level.muted ? 0 : (level.node?.audio?.volume ?? 0)
            onMoved: v => { if (level.node?.audio) { level.node.audio.muted = false; level.node.audio.volume = v } }
        }
        Text { textFormat: Text.PlainText;
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
            text: level.muted ? "0" : Math.round((level.node?.audio?.volume ?? 0) * 100)
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: Theme.textSmall
            font.features: ({ "tnum": 1 })
        }
    }

    component DeviceGroup: Group {
        id: list
        property var devices: []
        property var current: null
        property string kind: "sink"
        property string empty: ""

        SettingRow {
            label: list.kind === "sink" ? "Ses düzeyi" : "Giriş düzeyi"
            sub: list.current ? page.label(list.current) : list.empty
            Level {
                node: list.current
                icon: list.kind === "sink" ? "volume_up" : "mic"
                mutedIcon: list.kind === "sink" ? "volume_off" : "mic_off"
            }
        }
        Repeater {
            model: list.devices.length > 1 ? list.devices : []
            delegate: ListRow {
                required property var modelData
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                icon: list.kind === "sink" ? "speaker" : "mic"
                label: page.label(modelData)
                selected: modelData === list.current
                onClicked: {
                    if (list.kind === "sink") Pipewire.preferredDefaultAudioSink = modelData
                    else Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }
        Item { visible: list.devices.length > 1; implicitHeight: 4 }
    }

    DeviceGroup { title: Lang.t("Çıkış"); devices: page.sinks; current: page.defSink; kind: "sink"; empty: "Hoparlör ya da kulaklık bulunamadı" }
    DeviceGroup { title: Lang.t("Giriş"); devices: page.sources; current: page.defSource; kind: "source"; empty: "Mikrofon bulunamadı" }

    Group {
        title: Lang.t("Uygulamalar")
        Repeater {
            model: page.streams
            delegate: SettingRow {
                required property var modelData
                label: page.appName(modelData)
                Level { node: modelData }
            }
        }
        SettingRow {
            visible: page.streams.length === 0
            label: Lang.t("Şu an ses çalan bir uygulama yok")
        }
    }

    PillButton {
        label: Lang.t("Gelişmiş ses ayarları")
        icon: "tune"
        onClicked: Quickshell.execDetached(["pavucontrol"])
    }
}

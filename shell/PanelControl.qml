import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Kontrol merkezi: sık kullanılan anahtarlar, oturum, parlaklık ve ses.
ColumnLayout {
    id: root
    spacing: 10

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    PwObjectTracker { objects: [root.sink] }

    Component.onCompleted: Brightness.refresh()

    component Tile: Rectangle {
        id: tile
        property string icon: ""
        property string name: ""
        property string detail: ""
        property bool isOn: false
        property bool hasMore: false          // sağ üstte ok: ayrıntı paneline götürür
        signal toggled()
        signal more()

        Layout.fillWidth: true
        implicitHeight: 100
        radius: Theme.radiusTile
        color: isOn ? Theme.accent : (tileMouse.pressed ? Theme.pressed : tileMouse.containsMouse ? Theme.hover : Theme.well)
        Behavior on color { ColorAnimation { duration: Theme.state } }
        scale: tileMouse.pressed ? 0.975 : 1
        Behavior on scale { NumberAnimation { duration: Theme.fast } }
        Accessible.role: Accessible.CheckBox
        Accessible.name: name
        Accessible.checked: isOn

        readonly property color fg: isOn ? Theme.accentInk : Theme.paper

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }

        Icon {
            x: 13; y: 12
            name: tile.icon
            size: 23
            filled: tile.isOn
            color: tile.fg
        }
        IconButton {
            visible: tile.hasMore
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 5
            implicitWidth: 32; implicitHeight: 32
            radius: 10
            icon: "chevron_right"
            iconSize: 20
            iconColor: tile.fg
            tooltip: tile.name + " ayrıntıları"
            onClicked: tile.more()
        }
        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            anchors.bottomMargin: 12
            spacing: 1
            Text {
                width: parent.width
                text: tile.name
                color: tile.fg
                font.family: Theme.sans
                font.pixelSize: 14.5
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: tile.detail
                color: tile.fg
                opacity: 0.66
                font.family: Theme.sans
                font.pixelSize: 12.5
                elide: Text.ElideRight
            }
        }
    }

    component SessionButton: Rectangle {
        id: sb
        property string icon: ""
        property string tip: ""
        property color tone: Theme.paper
        signal clicked()
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 14
        color: sbMouse.pressed ? Theme.pressed : sbMouse.containsMouse ? Theme.hover : Theme.well
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Accessible.role: Accessible.Button
        Accessible.name: tip
        Icon { anchors.centerIn: parent; name: sb.icon; size: 20; color: sb.tone }
        MouseArea { id: sbMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sb.clicked() }
    }

    component Level: Rectangle {
        id: level
        property string icon: ""
        property real value: 0
        signal moved(real v)
        signal iconClicked()
        Layout.fillWidth: true
        implicitHeight: 48
        radius: Theme.radiusTile
        color: Theme.well
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 14
            spacing: 6
            IconButton {
                implicitWidth: 36; implicitHeight: 36
                icon: level.icon
                iconColor: Theme.soft
                onClicked: level.iconClicked()
            }
            VSlider {
                Layout.fillWidth: true
                value: level.value
                onMoved: v => level.moved(v)
            }
            Text {
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignRight
                text: Math.round(level.value * 100)
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 12.5
                font.features: ({ "tnum": 1 })
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 10
            columnSpacing: 10
            uniformCellWidths: true

            Tile {
                icon: Net.kind === "ethernet" ? "lan" : "wifi"
                name: Net.kind === "ethernet" ? "Ağ" : "Wi‑Fi"
                detail: Net.label
                isOn: Net.kind !== "none" || Net.wifiOn
                hasMore: true
                onToggled: Net.wifiAvailable ? Net.setWifi(!Net.wifiOn) : Ui.togglePopover("wifi", Ui.popoverScreen)
                onMore: Ui.togglePopover("wifi", Ui.popoverScreen)
            }
            Tile {
                icon: "bluetooth"
                name: "Bluetooth"
                detail: Bt.label
                isOn: Bt.isOn
                hasMore: Bt.available
                opacity: Bt.available ? 1 : 0.5
                onToggled: Bt.setOn(!Bt.isOn)
                onMore: Ui.togglePopover("bluetooth", Ui.popoverScreen)
            }
            Tile {
                icon: "do_not_disturb_on"
                name: "Rahatsız etme"
                detail: Notifs.dnd ? "Açık" : "Kapalı"
                isOn: Notifs.dnd
                onToggled: Notifs.dnd = !Notifs.dnd
            }
            Tile {
                icon: "nightlight"
                name: "Gece ışığı"
                detail: NightLight.label
                isOn: NightLight.isOn && !NightLight.failed
                onToggled: NightLight.toggle()
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 52
            Layout.fillHeight: true
            spacing: 10
            SessionButton { icon: "lock"; tip: "Kilitle"; onClicked: Ui.lock() }
            SessionButton { icon: "bedtime"; tip: "Uyku"; onClicked: { Ui.closeAll(); Ui.run(["systemctl", "suspend"]) } }
            SessionButton { icon: "power_settings_new"; tip: "Oturum menüsü"; tone: Theme.danger; onClicked: { Ui.closeAll(); Ui.sessionMenuOpen = true } }
        }
    }

    Level {
        visible: Brightness.available
        icon: "light_mode"
        value: Brightness.value
        onMoved: v => Brightness.set(v)
    }
    Level {
        icon: root.muted || root.volume === 0 ? "volume_off" : root.volume < 0.4 ? "volume_down" : "volume_up"
        value: root.muted ? 0 : root.volume
        onMoved: v => { if (root.sink?.audio) { root.sink.audio.muted = false; root.sink.audio.volume = v } }
        onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
    }

    // Güç kipi: yalnızca sistem destekliyorsa
    Segmented {
        id: profiles
        Layout.fillWidth: true
        visible: UPower.displayDevice?.isLaptopBattery ?? false
        readonly property var order: PowerProfiles.hasPerformanceProfile
            ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
            : [PowerProfile.PowerSaver, PowerProfile.Balanced]
        options: PowerProfiles.hasPerformanceProfile ? ["Tasarruf", "Dengeli", "Performans"] : ["Tasarruf", "Dengeli"]
        currentIndex: Math.max(0, order.indexOf(PowerProfiles.profile))
        stretch: true
        onPicked: i => PowerProfiles.profile = order[i]
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        PillButton {
            Layout.fillWidth: true
            icon: "settings"
            label: "Ayarlar"
            onClicked: Ui.settings()
        }
        Rectangle {
            visible: Niri.kbShort !== ""
            implicitWidth: 52
            implicitHeight: 42
            radius: Theme.radiusRow + 2
            color: kbMouse.pressed ? Theme.pressed : kbMouse.containsMouse ? Theme.hover : Theme.well
            Accessible.role: Accessible.Button
            Accessible.name: "Klavye düzeni: " + Niri.kbShort
            Text {
                anchors.centerIn: parent
                text: Niri.kbShort
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
            }
            MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Niri.action(["switch-layout", "next"]) }
        }
        IconButton {
            implicitWidth: 42; implicitHeight: 42
            radius: Theme.radiusRow + 2
            idle: Theme.well
            icon: "screenshot_region"
            tooltip: "Ekran görüntüsü"
            onClicked: Ui.screenshot()
        }
    }
}

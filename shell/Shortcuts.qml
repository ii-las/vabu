import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: Ui.shortcutsOpen
    color: Qt.rgba(12 / 255, 13 / 255, 18 / 255, 0.45)
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "vabu-shortcuts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var groups: [
        { title: "Pencereler ve kolonlar", color: Theme.sky, items: [
            ["Kolonlar arasında gez", ["v", "← →"]],
            ["Kolon içinde gez", ["v", "↑ ↓"]],
            ["Pencereyi taşı", ["v", "shift", "← →"]],
            ["Genişliği değiştir", ["v", "R"]],
            ["Kolonu büyüt / küçült", ["v", "+ −"]],
            ["Tam ekran", ["v", "shift", "F"]],
            ["Yüzen pencere", ["v", "V"]],
            ["Pencereyi kapat", ["v", "Q"]]
        ]},
        { title: "Vabu", color: Theme.mint, items: [
            ["Ara ve başlat", ["v", "space"]],
            ["Uygulama kur", ["v", "I"]],
            ["Genel bakış", ["v", "O"]],
            ["Çalışma alanına git", ["v", "1–9"]],
            ["Terminal", ["v", "⏎"]],
            ["Ekran görüntüsü", ["print"]],
            ["Ekranı kilitle", ["v", "alt", "L"]],
            ["Ayarlar", ["v", ","]]
        ]}
    ]

    MouseArea { anchors.fill: parent; onClicked: Ui.shortcutsOpen = false }

    Card {
        id: panel
        strong: true
        radius: 30
        marks: true
        width: Math.min(1040, parent.width - 80)
        height: Math.min(820, parent.height - 80)
        anchors.centerIn: parent
        focus: root.visible
        Keys.onPressed: event => { Ui.shortcutsOpen = false; event.accepted = true }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 36
            spacing: 22

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 6
                    Text { text: "SUPER + SHIFT + /"; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 1.6 }
                    Text { text: "Kısayollar"; color: Theme.paper; font.family: Theme.serif; font.pixelSize: 48 }
                }
                Item { Layout.fillWidth: true }
                Keycap { label: "v" }
                Text { text: " = Super tuşu"; color: Theme.soft; font.family: Theme.sans; font.pixelSize: 13 }
                IconButton { Layout.leftMargin: 16; icon: "close"; tooltip: "Kapat"; onClicked: Ui.shortcutsOpen = false }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 40
                Repeater {
                    model: root.groups
                    delegate: ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 0
                        Text {
                            Layout.bottomMargin: 8
                            text: group.modelData.title
                            color: group.modelData.color
                            font.family: Theme.serif
                            font.italic: true
                            font.pixelSize: 24
                        }
                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.dash }
                        Repeater {
                            model: group.modelData.items
                            delegate: ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 0
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 55
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData[0]
                                        color: Theme.paper
                                        font.family: Theme.sans
                                        font.pixelSize: 15
                                    }
                                    Repeater {
                                        model: modelData[1]
                                        delegate: Keycap { required property var modelData; label: modelData }
                                    }
                                }
                                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.dash }
                            }
                        }
                    }
                }
            }
        }
    }
}

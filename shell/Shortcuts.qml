import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Kısayol tablosu (Super + Shift + /). Herhangi bir tuş kapatır.
OverlayWindow {
    id: root
    open: Ui.shortcutsOpen
    dim: 0.5
    onDismissed: Ui.shortcutsOpen = false
    WlrLayershell.namespace: "vabu-shortcuts"
    onOpenChanged: if (open) keys.forceActiveFocus()

    readonly property var groups: [
        { title: "Gezinme", items: [
            ["Kolonlar arasında", ["Super", "←", "→"]],
            ["Pencereler ve alanlar arasında", ["Super", "↑", "↓"]],
            ["Çalışma alanına git", ["Super", "1…9"]],
            ["Pencere değiştir", ["Alt", "Tab"]],
            [Lang.t("Genel bakış"), ["Super", "O"]],
            ["Ekranlar arasında", ["Super", "Ctrl", "←", "→"]]
        ]},
        { title: Lang.t("Pencereler"), items: [
            ["Taşı", ["Super", "Shift", "yön"]],
            ["Başka alana taşı", ["Super", "Shift", "1…9"]],
            ["Genişliği değiştir", ["Super", "R"]],
            ["Kolonu büyüt", ["Super", "F"]],
            ["Tam ekran", ["Super", "Shift", "F"]],
            ["Yüzen pencere", ["Super", "V"]],
            ["Kolona al ya da çıkar", ["Super", "[", "]"]],
            [Lang.t("Kapat"), ["Super", "Q"]]
        ]},
        { title: "Vabu", items: [
            [Lang.t("Ara ve başlat"), ["Super", "Boşluk"]],
            [Lang.t("Uygulama kur"), ["Super", "I"]],
            ["Terminal", ["Super", "⏎"]],
            [Lang.t("Dosyalar"), ["Super", "E"]],
            [Lang.t("Kontrol merkezi"), ["Super", "A"]],
            [Lang.t("Bildirimler"), ["Super", "N"]],
            [Lang.t("Ayarlar"), ["Super", ","]],
            [Lang.t("Ekranı kilitle"), ["Super", "Alt", "L"]],
            [Lang.t("Ekran görüntüsü"), ["Print"]]
        ]}
    ]

    Card {
        id: panel
        tint: Theme.panelDeep
        radius: Theme.radiusPanel
        shadow: true
        width: Math.min(1120, parent.width - 80)
        height: Math.min(body.implicitHeight + 56, parent.height - 80)
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        opacity: Math.min(1, root.shown * 1.5)
        transform: Scale {
            origin.x: panel.width / 2; origin.y: panel.height / 2
            xScale: 0.96 + 0.04 * root.shown; yScale: 0.96 + 0.04 * root.shown
        }

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => { Ui.shortcutsOpen = false; event.accepted = true }
        }

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 28
            spacing: 22

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { textFormat: Text.PlainText;
                    Layout.fillWidth: true
                    text: Lang.t("Kısayollar")
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: Math.round((22) * Config.textScale)
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.3
                }
                IconButton { Layout.leftMargin: 10; icon: "close"; tooltip: Lang.t("Kapat"); onClicked: Ui.shortcutsOpen = false }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 36
                Repeater {
                    model: root.groups
                    delegate: ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 0
                        Text { textFormat: Text.PlainText;
                            Layout.bottomMargin: 10
                            text: group.modelData.title
                            color: Theme.muted
                            font.family: Theme.sans
                            font.pixelSize: Math.round((13) * Config.textScale)
                            font.weight: Font.Medium
                        }
                        DashLine { Layout.fillWidth: true }
                        Repeater {
                            model: group.modelData.items
                            delegate: ColumnLayout {
                                id: line
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 0
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    spacing: 5
                                    Text { textFormat: Text.PlainText;
                                        Layout.fillWidth: true
                                        text: line.modelData[0]
                                        color: Theme.paper
                                        font.family: Theme.sans
                                        font.pixelSize: Math.round((14) * Config.textScale)
                                        elide: Text.ElideRight
                                    }
                                    Repeater {
                                        model: line.modelData[1]
                                        delegate: Keycap { required property var modelData; label: modelData }
                                    }
                                }
                                DashLine { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }
        }
    }
}

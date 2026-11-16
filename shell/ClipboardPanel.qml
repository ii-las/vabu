import QtQuick
import QtQuick.Layouts
OverlayWindow {
    id: root
    open: Ui.clipboardOpen
    onDismissed: Ui.clipboardOpen = false
    onOpenChanged: if (open) Qt.callLater(() => query.focusField())
    Card {
        anchors.centerIn: parent
        width: Math.min(640, parent.width - 32); height: Math.min(560, parent.height - 32)
        tint: Theme.panelSolid
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 12
            Text { textFormat: Text.PlainText; text: Lang.t("Pano geçmişi"); color: Theme.paper; font.family: Theme.sans; font.pixelSize: Math.round((22) * Config.textScale)}
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: Config.clipboardEnabled ? Lang.t("Yalnızca bellekte saklanır. Kilitlenince ve 10 dakika sonra temizlenir.") : Lang.t("Pano geçmişi kapalı. Masaüstü ayarlarından etkinleştirebilirsin."); wrapMode: Text.Wrap; color: Theme.soft }
            Field { id: query; Layout.fillWidth: true; placeholder: Lang.t("Geçmişte ara") }
            Flow {
                Layout.fillWidth: true; spacing: 8
                PillButton { label: Clipboard.paused ? Lang.t("Sürdür") : Lang.t("Duraklat ve temizle"); enabled: Config.clipboardEnabled; onClicked: { Clipboard.paused = !Clipboard.paused; Clipboard.entries = [] } }
                PillButton { label: Lang.t("Geçmişi temizle"); onClicked: Clipboard.action("clear", "") }
                PillButton { label: Lang.t("Ayarlar"); onClicked: Ui.settings("desktop") }
            }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
                model: Clipboard.entries.filter(e => !query.text || e.text.toLocaleLowerCase().includes(query.text.toLocaleLowerCase()))
                delegate: RowLayout {
                    required property var modelData
                    width: ListView.view.width
                    PillButton { Layout.fillWidth: true; label: modelData.text.slice(0,90).replace(/\s+/g," "); onClicked: { Clipboard.action("copy",modelData.id); Ui.clipboardOpen = false } }
                    IconButton { icon: "delete"; tooltip: Lang.t("Sil"); onClicked: Clipboard.action("delete",modelData.id) }
                }
            }
            Text { textFormat: Text.PlainText; text: Clipboard.error; color: Theme.warn; wrapMode: Text.Wrap; Layout.fillWidth: true }
        }
    }
}

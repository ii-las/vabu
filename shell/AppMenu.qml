import QtQuick
import QtQuick.Layouts
import Quickshell
OverlayWindow {
    id: root
    open: Ui.appMenuEntry !== null
    onDismissed: Ui.appMenuEntry = null
    readonly property var entry: Ui.appMenuEntry
    function done() { Ui.appMenuEntry = null }
    Card {
        anchors.centerIn: parent
        width: Math.min(520, parent.width - 32)
        height: Math.min(body.implicitHeight + 32, parent.height - 32)
        tint: Theme.panelSolid
        Flickable {
            anchors.fill: parent; anchors.margins: 16; contentHeight: body.implicitHeight; clip: true
            ColumnLayout {
                id: body; width: parent.width; spacing: 12
                Text { textFormat: Text.PlainText; text: root.entry?.name ?? ""; color: Theme.paper; font.family: Theme.sans; font.pixelSize: Math.round((22) * Config.textScale); wrapMode: Text.Wrap; Layout.fillWidth: true }
                PillButton { label: Lang.t("Yeni pencere aç"); onClicked: { Apps.launch(root.entry); root.done() } }
                PillButton {
                    label: Config.pinned.some(id => Apps.byId(id) === root.entry) ? Lang.t("Sabitlemeyi kaldır") : Lang.t("Yan panele sabitle")
                    onClicked: { Apps.togglePin(root.entry); root.done() }
                }
                PillButton {
                    label: Lang.t("Harici GPU ile başlat")
                    visible: root.entry !== null && Gpu.available && !root.entry.runInTerminal && (root.entry.command?.length ?? 0) > 0
                    onClicked: { Ui.run(["switcherooctl", "launch"].concat(root.entry.command)); root.done() }
                }
                Repeater {
                    model: root.entry ? Apps.windowsOf(root.entry) : []
                    delegate: Group {
                        id: windowGroup
                        required property var modelData
                        title: modelData.title || modelData.app_id
                        PillButton { label: Lang.t("Pencereye git"); onClicked: { Niri.focusWindow(modelData.id); root.done() } }
                        Repeater {
                            model: Niri.workspaces
                            delegate: PillButton {
                                required property var modelData
                                label: Lang.t("Taşı: ") + (modelData.name || String(modelData.idx))
                                onClicked: { Niri.moveWindowToWorkspace(windowGroup.modelData.id, modelData); root.done() }
                            }
                        }
                    }
                }
                PillButton { label: Lang.t("Kapat"); onClicked: root.done() }
            }
        }
    }
}

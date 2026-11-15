import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: Notifs.popups.length > 0 && !Ui.notifCenterOpen
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: Theme.gap; right: Theme.gap }
    implicitWidth: 380
    implicitHeight: stack.implicitHeight + 4
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "vabu-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups
            delegate: NotificationCard {
                id: card
                required property var modelData
                Layout.fillWidth: true
                notif: modelData
                popup: true
                onClosed: Notifs.dismissPopup(modelData)

                Timer {
                    running: !card.critical
                    interval: card.notif.expireTimeout > 0 ? card.notif.expireTimeout : 6000
                    onTriggered: Notifs.dismissPopup(card.modelData)
                }

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: Theme.normal } }
            }
        }
    }
}

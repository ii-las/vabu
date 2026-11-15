import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: Notifs.visiblePopups.length > 0 && !Ui.notifCenterOpen
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
            model: Notifs.visiblePopups
            delegate: NotificationCard {
                id: card
                required property var modelData
                Layout.fillWidth: true
                notif: modelData
                popup: true
                onClosed: Notifs.dismissPopup(modelData)

                Timer {
                    // 0: uygulama "kendiliğinden kapanmasın" dedi; -1/eksik: varsayılan 6 sn (değer ms)
                    running: !card.critical && card.notif.expireTimeout !== 0
                    interval: card.notif.expireTimeout > 0 ? card.notif.expireTimeout : 6000
                    onTriggered: Notifs.dismissPopup(card.modelData)
                }

                opacity: 0
                transform: Translate {
                    id: slide
                    x: 40
                    Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                }
                Component.onCompleted: { opacity = 1; slide.x = 0 }
                Behavior on opacity { NumberAnimation { duration: Theme.normal } }
            }
        }
    }
}

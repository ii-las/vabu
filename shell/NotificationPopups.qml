import QtQuick
import Quickshell
import Quickshell.Wayland

// Köşede beliren bildirimler. Sağdan kayarak gelir, kapanınca altındakiler yerine oturur.
PanelWindow {
    id: root
    readonly property bool onRight: Config.sidebarSide === "right"
    readonly property int pad: 44                 // gölge için pay
    readonly property int cardWidth: 372

    visible: list.count > 0 && Ui.popover !== "notifications" && !Ui.locked
    color: "transparent"
    anchors { top: true; right: !onRight; left: onRight }
    implicitWidth: cardWidth + pad + Theme.gap + 4
    implicitHeight: Math.max(1, list.contentHeight + pad + Theme.gap + 4)
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: hit }

    WlrLayershell.namespace: "vabu-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property real originX: onRight ? 0 : (screen?.width ?? 0) - width

    // Tıklamalar yalnızca bildirimlerin kapladığı alanda yakalanır
    Item {
        id: hit
        x: list.x
        y: list.y
        width: list.width
        height: list.contentHeight
    }

    // Yükseklik içeriğe bağlanmaz: liste, görüş alanı sıfırken hiç öğe oluşturmaz
    ListView {
        id: list
        x: root.onRight ? Theme.gap + 4 : root.pad
        y: Theme.gap + 4
        width: root.cardWidth
        height: 1600
        spacing: 8
        interactive: false
        model: ScriptModel { values: Notifs.visiblePopups }

        delegate: NotificationCard {
            id: card
            required property var modelData
            width: list.width
            notif: modelData
            popup: true
            originX: root.originX
            onClosed: Notifs.dismissPopup(modelData)

            Timer {
                // Süre milisaniye gelir. 0: uygulama "kendiliğinden kapanmasın" dedi; eksi: varsayılan 6 sn
                running: !card.critical && card.notif.expireTimeout !== 0
                interval: card.notif.expireTimeout > 0 ? Math.max(2500, card.notif.expireTimeout) : 6000
                onTriggered: Notifs.dismissPopup(card.modelData)
            }
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Config.reducedMotion ? 0 : 240 }
                NumberAnimation { property: "x"; from: root.onRight ? -36 : 36; to: 0; duration: Theme.enter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.exit }
                NumberAnimation { property: "x"; to: root.onRight ? -28 : 28; duration: Theme.exit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.accelerate }
            }
        }
        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: Config.reducedMotion ? 0 : 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            NumberAnimation { property: "opacity"; to: 1; duration: Config.reducedMotion ? 0 : 200 }
        }
    }
}

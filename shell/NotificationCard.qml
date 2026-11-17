import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// Tek bir bildirim. Köşede (popup) buzlu cam, panelin içinde sade yüzey olarak çizilir.
Item {
    id: root
    required property var notif
    property bool popup: false
    property real originX: 0
    property real originY: 0
    signal closed()

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property string appIcon: notif?.appIcon ?? ""

    implicitHeight: col.implicitHeight + 28

    Card {
        visible: root.popup
        anchors.fill: parent
        tint: Theme.panelDeep
        shadow: true
        originX: root.originX
        originY: root.originY
        edgeColor: root.critical ? Theme.alpha(Theme.danger, 0.7) : Theme.edge
    }
    Rectangle {
        visible: !root.popup
        anchors.fill: parent
        radius: Theme.radiusTile
        color: hover.hovered ? Theme.hover : Theme.well
        border.width: root.critical ? 1 : 0
        border.color: Theme.alpha(Theme.danger, 0.7)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    HoverHandler { id: hover }

    RowLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12

        // Uygulama simgesi ya da gönderilen görsel
        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 36; implicitHeight: 36
            radius: 11
            color: Theme.well
            Icon {
                anchors.centerIn: parent
                visible: pic.status !== Image.Ready && appPic.status !== Image.Ready
                name: root.critical ? "error" : "notifications"
                size: 19
                color: root.critical ? Theme.danger : Theme.soft
            }
            Image {
                id: appPic
                anchors.centerIn: parent
                width: 24; height: 24
                visible: status === Image.Ready && pic.status !== Image.Ready
                // simge adı ya da doğrudan bir dosya yolu gelebilir
                source: root.appIcon === "" ? ""
                    : root.appIcon.startsWith("/") ? "file://" + root.appIcon
                    : root.appIcon.startsWith("file://") ? root.appIcon
                    : Quickshell.iconPath(root.appIcon, true)
                sourceSize: Qt.size(48, 48)
                asynchronous: true
            }
            Image {
                id: pic
                anchors.fill: parent
                visible: status === Image.Ready
                source: root.notif?.image ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { textFormat: Text.PlainText;
                    Layout.fillWidth: true
                    text: root.notif?.appName || "Bildirim"
                    color: Theme.muted
                    font.family: Theme.sans
                    font.pixelSize: Theme.textSmall
                    elide: Text.ElideRight
                }
                IconButton {
                    implicitWidth: 24; implicitHeight: 24
                    radius: 8
                    opacity: hover.hovered || root.popup ? 1 : 0
                    icon: "close"; iconSize: 15
                    iconColor: Theme.muted
                    tooltip: Lang.t("Kapat")
                    onClicked: { root.notif.dismiss(); root.closed() }
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                }
            }
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                text: root.notif?.summary ?? ""
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: Math.round((14) * Config.textScale)
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif?.body ?? ""
                color: Theme.soft
                font.family: Theme.sans
                font.pixelSize: Theme.textSmall
                lineHeight: 1.18
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 3 : 5
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Flow {
                visible: (root.notif?.actions.length ?? 0) > 0
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 6
                Repeater {
                    model: root.notif?.actions ?? []
                    delegate: Rectangle {
                        id: act
                        required property var modelData
                        required property int index
                        readonly property bool main: index === 0
                        height: 32
                        width: label.implicitWidth + 26
                        radius: 10
                        color: main ? Theme.accent : (actMouse.containsMouse ? Theme.hover : Theme.well)
                        Text { textFormat: Text.PlainText;
                            id: label
                            anchors.centerIn: parent
                            text: act.modelData.text
                            color: act.main ? Theme.accentInk : Theme.paper
                            font.family: Theme.sans
                            font.pixelSize: Theme.textSmall
                            font.weight: act.main ? Font.DemiBold : Font.Medium
                        }
                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { act.modelData.invoke(); root.closed() }
                        }
                    }
                }
            }
        }
    }
}

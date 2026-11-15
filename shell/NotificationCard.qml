import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Card {
    id: root
    required property var notif
    property bool popup: false
    signal closed()

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical

    strong: true
    radius: 18
    border.color: critical ? Theme.coral : Theme.line
    implicitHeight: col.implicitHeight + 32

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                implicitWidth: 6; implicitHeight: 6; radius: 3
                color: root.critical ? Theme.coral : Theme.accent
            }
            Text {
                Layout.fillWidth: true
                text: (root.notif.appName || "Bildirim").toUpperCase()
                color: Theme.muted
                font.family: Theme.mono
                font.pixelSize: 10
                font.letterSpacing: 1.2
                elide: Text.ElideRight
            }
            IconButton {
                implicitWidth: 28; implicitHeight: 28
                icon: "close"; iconSize: 13
                tooltip: "Kapat"
                onClicked: { root.notif.dismiss(); root.closed() }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ClippingRectangle {
                visible: root.notif.image !== ""
                implicitWidth: 44; implicitHeight: 44; radius: 10
                Image { anchors.fill: parent; source: root.notif.image; fillMode: Image.PreserveAspectCrop }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    Layout.fillWidth: true
                    text: root.notif.summary
                    color: Theme.paper
                    font.family: Theme.serif
                    font.pixelSize: 21
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notif.body
                    color: Theme.soft
                    font.family: Theme.sans
                    font.pixelSize: 13
                    lineHeight: 1.15
                    wrapMode: Text.Wrap
                    maximumLineCount: root.popup ? 3 : 6
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }
        }

        RowLayout {
            visible: root.notif.actions.length > 0
            Layout.topMargin: 4
            spacing: 8
            Repeater {
                model: root.notif.actions
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    implicitHeight: 34
                    implicitWidth: label.implicitWidth + 28
                    radius: 17
                    color: index === 0 ? Theme.mint : "transparent"
                    border.color: index === 0 ? Theme.mint : Qt.rgba(1, 1, 1, 0.16)
                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: parent.index === 0 ? Theme.mintInk : Theme.paper
                        font.family: Theme.sans
                        font.pixelSize: 13
                        font.weight: parent.index === 0 ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { parent.modelData.invoke(); root.closed() }
                    }
                }
            }
        }
    }
}

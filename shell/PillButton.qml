import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property bool primary: false
    signal clicked()

    implicitHeight: 48
    implicitWidth: row.implicitWidth + 36
    radius: height / 2
    color: primary ? Theme.mint : (mouse.containsMouse ? Qt.rgba(243 / 255, 241 / 255, 236 / 255, 0.2) : Qt.rgba(243 / 255, 241 / 255, 236 / 255, 0.14))
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Accessible.role: Accessible.Button
    Accessible.name: label

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10
        Icon { visible: root.icon !== ""; name: root.icon; size: 17; color: root.primary ? Theme.mintInk : Theme.paper }
        Text {
            text: root.label
            color: root.primary ? Theme.mintInk : Theme.paper
            font.family: Theme.sans
            font.pixelSize: 14
            font.weight: root.primary ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

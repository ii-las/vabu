import QtQuick

Rectangle {
    id: root
    property string icon: ""
    property color iconColor: Theme.paper
    property real iconSize: 17
    property string tooltip: ""
    signal clicked()

    implicitWidth: 44
    implicitHeight: 40
    radius: Theme.radiusRow
    color: mouse.containsMouse ? Theme.hover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Accessible.role: Accessible.Button
    Accessible.name: tooltip

    Icon {
        anchors.centerIn: parent
        name: root.icon
        color: root.iconColor
        size: root.iconSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

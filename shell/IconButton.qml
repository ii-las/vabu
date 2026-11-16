import QtQuick

// İkon düğmesi. `active` iken kağıt zemin, koyu ikon.
Rectangle {
    id: root
    property string icon: ""
    property color iconColor: Theme.paper
    property real iconSize: 20
    property string tooltip: ""
    property bool active: false
    property bool filled: active
    signal clicked()

    implicitWidth: 40
    implicitHeight: 40
    radius: Theme.radiusRow
    color: active ? Theme.accent : (mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    scale: mouse.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }

    Accessible.role: Accessible.Button
    Accessible.name: tooltip

    Icon {
        anchors.centerIn: parent
        name: root.icon
        color: root.active ? Theme.accentInk : root.iconColor
        size: root.iconSize
        filled: root.filled
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

import QtQuick

// İkon düğmesi. `active` iken kağıt zemin, koyu ikon.
Rectangle {
    id: root
    activeFocusOnTab: true
    Keys.onSpacePressed: if (enabled) root.clicked()
    Keys.onReturnPressed: if (enabled) root.clicked()
    Keys.onEnterPressed: if (enabled) root.clicked()
    property string icon: ""
    property color iconColor: Theme.paper
    property real iconSize: 20
    property string tooltip: ""
    property bool active: false
    property bool filled: active
    property color idle: "transparent"    // boştayken zemin
    signal clicked()

    implicitWidth: 40
    implicitHeight: 40
    radius: Theme.radiusRow
    color: active ? Theme.accent : (mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : idle)
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    scale: 1
    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standard } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: root.radius + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        visible: root.activeFocus && root.enabled
    }

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
        onClicked: { root.forceActiveFocus(Qt.MouseFocusReason); root.clicked() }
    }
}

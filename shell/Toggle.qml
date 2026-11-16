import QtQuick

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 44
    implicitHeight: 26
    radius: 13
    color: checked ? Theme.accent : Qt.rgba(1, 1, 1, 0.13)
    Behavior on color { ColorAnimation { duration: Theme.state } }

    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked

    Rectangle {
        width: 20; height: 20; radius: 10
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.accentInk : Theme.muted
        Behavior on x { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on color { ColorAnimation { duration: Theme.state } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}

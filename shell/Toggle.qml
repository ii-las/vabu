import QtQuick

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 52
    implicitHeight: 30
    radius: 15
    color: checked ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked

    Rectangle {
        width: 24; height: 24; radius: 12
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? "#16161B" : Theme.faint
        Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}

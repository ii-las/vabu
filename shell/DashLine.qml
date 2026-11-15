import QtQuick

Row {
    id: root
    property color color: Theme.dash
    height: 1
    clip: true
    spacing: 3
    Repeater {
        model: Math.ceil(root.width / 7)
        delegate: Rectangle { width: 4; height: 1; color: root.color }
    }
}

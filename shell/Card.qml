import QtQuick

Rectangle {
    id: root
    property bool marks: false
    property bool strong: false

    radius: Theme.radiusCard
    color: strong ? Theme.glassStrong : Theme.glass
    border.color: Theme.line
    border.width: 1

    Text {
        visible: root.marks
        text: "+"
        x: -4; y: -10
        color: Qt.rgba(243 / 255, 241 / 255, 236 / 255, 0.5)
        font.family: Theme.mono
        font.pixelSize: 12
    }
    Text {
        visible: root.marks
        text: "+"
        x: root.width - 4; y: root.height - 6
        color: Qt.rgba(243 / 255, 241 / 255, 236 / 255, 0.5)
        font.family: Theme.mono
        font.pixelSize: 12
    }
}

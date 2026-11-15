import QtQuick

Rectangle {
    id: root
    property string label: ""
    readonly property bool superKey: label === "v"

    implicitWidth: Math.max(40, cap.implicitWidth + 20)
    implicitHeight: 40
    radius: 12
    color: superKey ? Theme.mint : Qt.rgba(1, 1, 1, 0.06)
    border.color: superKey ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.22)

    Text {
        id: cap
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.superKey ? -2 : 0
        text: root.label
        color: root.superKey ? Theme.mintInk : Theme.paper
        font.family: root.superKey ? Theme.serif : Theme.mono
        font.italic: root.superKey
        font.pixelSize: root.superKey ? 24 : 12
    }
}

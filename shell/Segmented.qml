import QtQuick

Rectangle {
    id: root
    property var options: []          // metin listesi
    property int currentIndex: 0
    property bool mono: false
    signal picked(int index)

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 44
    radius: 14
    color: Qt.rgba(1, 1, 1, 0.05)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            model: root.options
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool on: root.currentIndex === index
                width: label.implicitWidth + 30
                height: 36
                radius: 10
                color: on ? Theme.accent : (mouse.containsMouse ? Theme.hover : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                Accessible.role: Accessible.RadioButton
                Accessible.checked: on
                Accessible.name: modelData
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: parent.on ? Theme.accentInk : Theme.soft
                    font.family: root.mono ? Theme.mono : Theme.sans
                    font.pixelSize: root.mono ? 12 : 13
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(parent.index)
                }
            }
        }
    }
}

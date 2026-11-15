import QtQuick

Rectangle {
    id: root
    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""
    property bool mono: false
    signal accepted()

    implicitWidth: 260
    implicitHeight: 42
    radius: 12
    color: Theme.stoneHi
    border.width: 2
    border.color: input.activeFocus ? Theme.accent : "transparent"

    function focusField() { input.forceActiveFocus() }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.paper
        font.family: root.mono ? Theme.mono : Theme.sans
        font.pixelSize: 14
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentInk
        clip: true
        onAccepted: root.accepted()
        Text {
            visible: !input.text && !input.activeFocus
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.faint
            font: input.font
        }
    }
}

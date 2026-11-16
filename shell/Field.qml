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
    radius: Theme.radiusRow
    color: input.activeFocus ? Qt.rgba(1, 1, 1, 0.07) : Theme.well
    border.width: 1
    border.color: input.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55) : Theme.edge
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

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
            visible: !input.text
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.faint
            font: input.font
        }
    }
}

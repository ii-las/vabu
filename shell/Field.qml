import QtQuick

Rectangle {
    id: root
    property alias text: input.text
    property alias echoMode: input.echoMode
    property string accessibleLabel: placeholder
    property string placeholder: ""
    property bool mono: false
    signal accepted()

    implicitWidth: 260
    implicitHeight: Math.max(42, Math.ceil(input.implicitHeight + 18))
    radius: Theme.radiusRow
    color: input.activeFocus ? Theme.hover : Theme.well
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Theme.accent : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

    function focusField() { input.forceActiveFocus() }

    TextInput {
        id: input
        Accessible.name: root.accessibleLabel
        activeFocusOnTab: true
        selectByMouse: true
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.paper
        font.family: root.mono ? Theme.mono : Theme.sans
        font.pixelSize: Theme.textBody
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentInk
        clip: true
        onAccepted: root.accepted()
        Text { textFormat: Text.PlainText;
            visible: !input.text
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: Theme.faint
            font: input.font
        }
    }
}

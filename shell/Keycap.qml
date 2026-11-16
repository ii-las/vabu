import QtQuick

// Klavye tuşu. "v" Super tuşunu, Vabu tuşunu temsil eder.
Rectangle {
    id: root
    property string label: ""
    readonly property bool superKey: label === "v"

    implicitWidth: Math.max(34, cap.implicitWidth + 18)
    implicitHeight: 34
    radius: 9
    color: superKey ? Theme.accent : Qt.rgba(1, 1, 1, 0.06)
    border.color: superKey ? "transparent" : Qt.rgba(1, 1, 1, 0.09)
    border.width: 1

    // alt kenar: tuşa hafif derinlik
    Rectangle {
        visible: !root.superKey
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 2 * parent.radius
        height: 1
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Text {
        id: cap
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.superKey ? -1 : 0
        text: root.label
        color: root.superKey ? Theme.accentInk : Theme.paper
        font.family: root.superKey ? Theme.serif : Theme.sans
        font.italic: root.superKey
        font.weight: root.superKey ? Font.Medium : Font.Medium
        font.pixelSize: root.superKey ? 20 : 12.5
    }
}

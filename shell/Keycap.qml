import QtQuick

// Klavye tuşu. "v" Super tuşunu, Vabu tuşunu temsil eder.
Rectangle {
    id: root
    property string label: ""
    readonly property bool superKey: label === "Super"

    implicitWidth: Math.max(34, cap.implicitWidth + 18)
    implicitHeight: 34
    radius: 9
    color: superKey ? Theme.accent : Theme.well
    border.color: superKey ? "transparent" : Theme.line
    border.width: 1

    // alt kenar: tuşa hafif derinlik
    Rectangle {
        visible: !root.superKey
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 2 * parent.radius
        height: 1
        color: Theme.alpha(Theme.paper, 0.18)
    }

    Text { textFormat: Text.PlainText;
        id: cap
        anchors.centerIn: parent
        text: root.label
        color: root.superKey ? Theme.accentInk : Theme.paper
        font.family: Theme.sans
        font.weight: root.superKey ? Font.DemiBold : Font.Medium
        font.pixelSize: Math.round((12) * Config.textScale)
    }
}

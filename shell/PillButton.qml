import QtQuick
import QtQuick.Layouts

// Metinli düğme. `primary`: kağıt zemin; değilse sakin yüzey.
Rectangle {
    id: root
    activeFocusOnTab: true
    Keys.onSpacePressed: if (enabled) root.clicked()
    Keys.onReturnPressed: if (enabled) root.clicked()
    Keys.onEnterPressed: if (enabled) root.clicked()
    property string icon: ""
    property string label: ""
    property bool primary: false
    signal clicked()

    implicitHeight: 42
    implicitWidth: row.implicitWidth + 32
    radius: Theme.radiusRow + 2
    color: primary ? Theme.accent
         : mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : Theme.well
    opacity: enabled ? 1 : 0.45
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    scale: mouse.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: Theme.fast } }
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: root.radius + 3
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        visible: root.activeFocus
    }

    Accessible.role: Accessible.Button
    Accessible.name: label

    RowLayout {
        id: row
        anchors.centerIn: parent
        width: Math.min(implicitWidth, Math.max(0, root.width - 32))
        spacing: 8
        Icon { visible: root.icon !== ""; name: root.icon; size: 18; color: root.primary ? Theme.accentInk : Theme.paper }
        Text { textFormat: Text.PlainText;
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.label
            color: root.primary ? Theme.accentInk : Theme.paper
            font.family: Theme.sans
            font.pixelSize: Math.round((14) * Config.textScale)
            font.weight: root.primary ? Font.DemiBold : Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

import QtQuick
import QtQuick.Layouts

// Bir gruptaki seçim satırı: solda ad, sağda değer ve ok. Alt sayfayı açar.
Item {
    id: root
    property string label: ""
    property string value: ""
    signal activated()

    implicitHeight: 56
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label + ": " + value

    Keys.onReturnPressed: root.activated()
    Keys.onEnterPressed: root.activated()
    Keys.onSpacePressed: root.activated()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 11
        color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.alpha(Theme.accent, 0.6)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 6
        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: 14
            font.weight: Font.Medium
        }
        Text {
            text: root.value
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: 14
            elide: Text.ElideLeft
            Layout.maximumWidth: root.width * 0.6
        }
        Icon { name: "chevron_right"; size: 20; color: Theme.muted }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

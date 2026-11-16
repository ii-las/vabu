import QtQuick
import QtQuick.Layouts

// Listelerde tıklanabilir satır: solda simge, ortada ad ve açıklama, sağda durum.
Item {
    id: root
    activeFocusOnTab: true
    Keys.onReturnPressed: if (enabled) root.clicked()
    Keys.onSpacePressed: if (enabled) root.clicked()
    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool selected: false         // bağlı / seçili: onay işareti
    property bool busy: false             // dönen gösterge
    property string trailing: ""          // sağda küçük simge (ör. kilit)
    property color iconColor: Theme.paper
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: sub !== "" ? 52 : 44
    Accessible.role: Accessible.Button
    Accessible.name: label

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusRow
        color: mouse.pressed ? Theme.pressed : mouse.containsMouse || root.activeFocus ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Icon { name: root.icon; size: 20; color: root.iconColor; filled: root.selected }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                text: root.label
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: Math.round((14) * Config.textScale)
                font.weight: root.selected ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
            }
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                visible: root.sub !== ""
                text: root.sub
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: Math.round((12) * Config.textScale)
                elide: Text.ElideRight
            }
        }
        Icon {
            visible: root.trailing !== "" && !root.busy && !root.selected
            name: root.trailing
            size: 16
            color: Theme.faint
        }
        Icon {
            visible: root.selected && !root.busy
            name: "check"
            size: 19
            weight: 400
            color: Theme.paper
        }
        Spinner { visible: root.busy; running: root.busy }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

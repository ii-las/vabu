import QtQuick
import QtQuick.Layouts

// Ayar satırı: solda ad ve açıklama, sağda denetim. Bir Group içinde durur;
// ilk satır dışındakiler üstlerinde ince bir ayırıcı çizer.
Item {
    id: root
    property string label: ""
    property string sub: ""
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(58, rowLayout.implicitHeight + 26)

    Rectangle {
        visible: root.y > 1
        x: 16
        width: parent.width - 32
        height: 1
        color: Theme.line
    }

    GridLayout {
        id: rowLayout
        columns: root.width < 540 ? 1 : 2
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        rowSpacing: 10
        columnSpacing: 16
        ColumnLayout {
            id: texts
            Layout.fillWidth: true
            spacing: 3
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                text: root.label
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: Math.round((14) * Config.textScale)
                font.weight: Font.Medium
                wrapMode: Text.Wrap
            }
            Text { textFormat: Text.PlainText;
                Layout.fillWidth: true
                visible: root.sub !== ""
                text: root.sub
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: Math.round((12) * Config.textScale)
                lineHeight: 1.15
                wrapMode: Text.Wrap
            }
        }
        Flow {
            id: slot
            readonly property string accessibleLabel: root.label
            Layout.maximumWidth: rowLayout.width
            Layout.fillWidth: rowLayout.columns === 1
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: 8
        }
    }
}

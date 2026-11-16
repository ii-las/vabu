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
    implicitHeight: Math.max(58, texts.implicitHeight + 26)

    Rectangle {
        visible: root.y > 1
        x: 16
        width: parent.width - 32
        height: 1
        color: Theme.line
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16
        ColumnLayout {
            id: texts
            Layout.fillWidth: true
            spacing: 3
            Text {
                Layout.fillWidth: true
                text: root.label
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 14
                font.weight: Font.Medium
                wrapMode: Text.Wrap
            }
            Text {
                Layout.fillWidth: true
                visible: root.sub !== ""
                text: root.sub
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 12
                lineHeight: 1.15
                wrapMode: Text.Wrap
            }
        }
        Row {
            id: slot
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            spacing: 8
        }
    }
}

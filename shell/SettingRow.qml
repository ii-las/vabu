import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string label: ""
    property string sub: ""
    property bool divider: true
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(60, texts.implicitHeight + 24)

    RowLayout {
        anchors.fill: parent
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

    DashLine { visible: root.divider; anchors.bottom: parent.bottom; width: parent.width }
}

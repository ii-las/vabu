import QtQuick
import QtQuick.Layouts

// Açılır panellerin başlık satırı: ad, isteğe bağlı açıklama, sağda denetimler.
RowLayout {
    id: root
    property string title: ""
    property string sub: ""
    default property alias controls: slot.data

    Layout.fillWidth: true
    Layout.leftMargin: 6
    Layout.rightMargin: 2
    Layout.bottomMargin: 4
    spacing: 10

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text { textFormat: Text.PlainText;
            Layout.fillWidth: true
            text: root.title
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: Math.round((17) * Config.textScale)
            font.weight: Font.DemiBold
            font.letterSpacing: -0.2
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
    Row {
        id: slot
        Layout.alignment: Qt.AlignVCenter
        spacing: 4
    }
}

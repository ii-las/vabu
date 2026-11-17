import QtQuick
import QtQuick.Layouts

// Ayarlar sayfalarında bir grup: başlık, altında satırları taşıyan yüzey, isteğe bağlı not.
ColumnLayout {
    id: root
    property string title: ""
    property string note: ""
    default property alias rows: inner.data

    Layout.fillWidth: true
    spacing: 8

    Text { textFormat: Text.PlainText;
        visible: root.title !== ""
        Layout.leftMargin: 4
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: root.title
        color: Theme.muted
        font.family: Theme.sans
        font.pixelSize: Math.round((13) * Config.textScale)
        font.weight: Font.Medium
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight
        radius: Theme.radiusTile
        color: Theme.group
        border.width: 1
        border.color: Theme.groupEdge
        ColumnLayout {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0
        }
    }
    Text { textFormat: Text.PlainText;
        visible: root.note !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        text: root.note
        color: Theme.faint
        font.family: Theme.sans
        font.pixelSize: Theme.textSmall
        lineHeight: 1.2
        wrapMode: Text.Wrap
    }
}

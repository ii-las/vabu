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

    Text {
        visible: root.title !== ""
        Layout.leftMargin: 4
        text: root.title
        color: Theme.muted
        font.family: Theme.sans
        font.pixelSize: 13
        font.weight: Font.Medium
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight
        radius: Theme.radiusTile
        color: Qt.rgba(1, 1, 1, 0.035)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.05)
        ColumnLayout {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0
        }
    }
    Text {
        visible: root.note !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        text: root.note
        color: Theme.faint
        font.family: Theme.sans
        font.pixelSize: 12
        lineHeight: 1.2
        wrapMode: Text.Wrap
    }
}

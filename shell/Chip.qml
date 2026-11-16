import QtQuick

// Durum etiketi: renkli küçük nokta + sakin metin.
Rectangle {
    id: root
    property string text: ""
    property string kind: "ok"     // ok | warn | off | info
    readonly property color tone: kind === "ok" ? Theme.ok : kind === "warn" ? Theme.warn : kind === "info" ? Theme.sky : Theme.faint

    implicitWidth: row.implicitWidth + 22
    implicitHeight: 26
    radius: 13
    color: Theme.well

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7
        Rectangle { width: 6; height: 6; radius: 3; color: root.tone; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: root.text
            color: root.kind === "off" ? Theme.muted : Theme.soft
            font.family: Theme.sans
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }
}

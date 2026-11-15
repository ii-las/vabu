import QtQuick

Rectangle {
    id: root
    property string text: ""
    property string kind: "ok"     // ok | warn | off | info
    readonly property color tone: kind === "ok" ? Theme.mint : kind === "warn" ? Theme.peach : kind === "info" ? Theme.sky : Theme.soft

    implicitWidth: label.implicitWidth + 20
    implicitHeight: 26
    radius: 13
    color: Qt.rgba(tone.r, tone.g, tone.b, kind === "off" ? 0.08 : 0.16)

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.tone
        font.family: Theme.mono
        font.pixelSize: 10
        font.letterSpacing: 0.8
    }
}

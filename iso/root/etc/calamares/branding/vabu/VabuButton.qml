import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as Controls

// Qt's button keeps mouse, keyboard, focus and accessibility behavior together.
Controls.Button {
    id: control
    property bool primary: false
    implicitWidth: Math.max(120, implicitContentWidth + 40)
    implicitHeight: 44
    padding: 12
    font.family: "Hanken Grotesk"
    font.pixelSize: 15
    font.weight: Font.Medium
    focusPolicy: Qt.StrongFocus
    onPressed: if (control.Window.window) control.Window.window.requestActivate()
    hoverEnabled: true
    Accessible.name: text
    contentItem: Text {
        text: control.text
        font: control.font
        color: !control.enabled ? "#666E66" : control.primary ? "#FFFFFF" : "#222725"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 10
        color: !control.enabled ? "#E5E7E0"
             : control.primary ? (control.down ? "#2347AE" : control.hovered ? "#284EBD" : "#2C56CC")
             : control.down ? "#D0D5CA" : control.hovered ? "#DDE0D7" : "#E8E8E2"
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 13
            color: "transparent"
            border.width: 2
            border.color: "#2C56CC"
            visible: control.visualFocus && control.enabled
        }
    }
}

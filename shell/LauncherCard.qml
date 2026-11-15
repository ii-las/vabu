import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root
    property var entry: null
    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool highlight: false
    property bool selected: false
    signal activated()

    implicitHeight: 112
    radius: 18
    color: highlight ? Theme.accent : (mouse.containsMouse || selected ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.06))
    Behavior on color { ColorAnimation { duration: Theme.fast } }
    Accessible.role: Accessible.Button
    Accessible.name: title

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        anchors.leftMargin: 16

        Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 9
            color: root.highlight ? Theme.accentInk : Qt.rgba(1, 1, 1, 0.08)
            Icon {
                visible: root.glyph !== ""
                anchors.centerIn: parent
                name: root.glyph
                color: root.highlight ? Theme.accent : Theme.paper
                size: 16
            }
            IconImage {
                visible: root.entry !== null
                anchors.centerIn: parent
                implicitSize: 22
                source: root.entry ? Quickshell.iconPath(root.entry.icon, "application-x-executable") : ""
            }
        }
        Item { Layout.fillHeight: true }
        Text {
            Layout.fillWidth: true
            text: root.title
            color: root.highlight ? Theme.accentInk : Theme.paper
            font.family: Theme.serif
            font.pixelSize: 22
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: root.subtitle
            color: root.highlight ? Theme.accentInk : Theme.paper
            opacity: 0.7
            font.family: Theme.sans
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

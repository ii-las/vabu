import QtQuick
import QtQuick.Layouts

Card {
    id: root
    property string output: ""
    property real screenWidth: 1920
    visible: Niri.available && workspaces.length > 0
    implicitHeight: col.implicitHeight + 24

    readonly property var workspaces: Niri.workspacesOn(output)

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4

        Text {
            Layout.leftMargin: 6
            Layout.bottomMargin: 4
            text: "ÇALIŞMA ALANLARI"
            color: Theme.muted
            font.family: Theme.mono
            font.pixelSize: 10
            font.letterSpacing: 1.4
        }

        Repeater {
            model: root.workspaces
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool isOn: modelData.is_active
                readonly property var cols: Niri.columnsFor(modelData.id)

                Layout.fillWidth: true
                implicitHeight: 38
                radius: Theme.radiusRow
                color: isOn ? Theme.accent : (mouse.containsMouse ? Theme.hover : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.normal } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        Layout.preferredWidth: 22
                        text: row.modelData.idx
                        color: row.isOn ? Theme.accentInk : Theme.paper
                        font.family: Theme.serif
                        font.pixelSize: 20
                    }

                    Row {
                        Layout.fillWidth: true
                        spacing: 3
                        Repeater {
                            model: row.cols
                            delegate: Rectangle {
                                required property var modelData
                                width: Math.max(8, Math.min(40, modelData.width / root.screenWidth * 64))
                                height: 14
                                radius: 4
                                color: modelData.focused ? (row.isOn ? Theme.accentInk : Theme.paper) : "transparent"
                                border.width: 1
                                border.color: row.isOn ? Qt.rgba(20 / 255, 36 / 255, 63 / 255, 0.55) : Qt.rgba(1, 1, 1, 0.32)
                                Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                            }
                        }
                        Text {
                            visible: row.cols.length === 0
                            text: "boş"
                            color: row.isOn ? Theme.accentInk : Theme.faint
                            font.family: Theme.mono
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        text: row.modelData.name || (row.cols.length ? row.cols.length + " kolon" : "")
                        color: row.isOn ? Theme.accentInk : Theme.muted
                        font.family: Theme.mono
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.focusWorkspace(row.modelData)
                }
            }
        }
    }
}

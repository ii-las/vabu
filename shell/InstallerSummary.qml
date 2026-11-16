import QtQuick
import QtQuick.Layouts

// Özet: kurulumdan önce seçilenler.
InstallerPage {
    key: "summary"
    step: 4
    heading: InstallerState.s.summary
    nextLabel: InstallerState.s.installButton

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: rows.implicitHeight
        radius: 14
        color: InstallerState.group
        border.width: 1
        border.color: Theme.groupEdge

        ColumnLayout {
            id: rows
            width: parent.width
            spacing: 0
            Repeater {
                model: InstallerState.summaryRows
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Math.max(62, texts.implicitHeight + 24)

                    Rectangle {
                        visible: row.index > 0
                        x: 16
                        width: parent.width - 32
                        height: 1
                        color: Theme.line
                    }
                    Icon {
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.icon
                        size: 20
                        color: Theme.soft
                    }
                    ColumnLayout {
                        id: texts
                        x: 50
                        width: parent.width - 66
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.label
                            color: Theme.paper
                            font.family: Theme.sans
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.sub
                            color: Theme.muted
                            font.family: Theme.sans
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}

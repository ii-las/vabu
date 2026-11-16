import QtQuick
import QtQuick.Layouts

// Disk kartı. Seçilince kenarı vurgu rengine döner. Çok küçük diskler seçilemez.
Rectangle {
    id: root
    property var disk: ({})
    property bool selected: false
    signal picked()

    readonly property bool usable: !(disk.tooSmall ?? false)

    implicitHeight: 68
    radius: 14
    color: mouse.containsMouse && usable && !selected ? Qt.tint(InstallerState.group, Theme.hover) : InstallerState.group
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.accent : Theme.groupEdge
    opacity: usable ? 1 : 0.5
    activeFocusOnTab: usable
    Behavior on border.color { ColorAnimation { duration: Theme.state } }

    Accessible.role: Accessible.RadioButton
    Accessible.name: InstallerState.diskName(disk)
    Accessible.checked: selected

    Keys.onSpacePressed: root.picked()
    // Enter hem seçer hem sayfayı ilerletir
    Keys.onReturnPressed: event => { root.picked(); event.accepted = false }
    Keys.onEnterPressed: event => { root.picked(); event.accepted = false }

    Rectangle {
        visible: root.activeFocus
        anchors.fill: parent
        anchors.margins: -4
        radius: root.radius + 4
        color: "transparent"
        border.width: 2
        border.color: Theme.alpha(Theme.accent, 0.45)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14
        Icon {
            name: root.disk.transport === "usb" || root.disk.removable ? "usb" : "hard_drive"
            size: 24
            filled: root.selected
            color: root.selected ? Theme.accent : Theme.soft
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: InstallerState.diskName(root.disk)
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: InstallerState.diskSub(root.disk)
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
        Icon {
            name: root.selected ? "radio_button_checked" : "radio_button_unchecked"
            size: 22
            filled: root.selected
            color: root.selected ? Theme.accent : Theme.muted
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.usable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
    }
}

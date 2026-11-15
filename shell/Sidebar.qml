import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property bool onRight: Config.sidebarSide === "right"

    anchors {
        top: true
        bottom: true
        left: !onRight
        right: onRight
    }
    implicitWidth: Theme.sidebarWidth
    exclusiveZone: Theme.sidebarWidth
    color: "transparent"

    WlrLayershell.namespace: "vabu-sidebar"
    WlrLayershell.layer: WlrLayer.Top

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gap
        spacing: 10

        SidebarClock { Layout.fillWidth: true }
        SidebarWorkspaces {
            Layout.fillWidth: true
            output: root.screen?.name ?? ""
            screenWidth: root.screen?.width ?? 1920
        }
        SidebarApps { Layout.fillWidth: true }
        SidebarMedia { Layout.fillWidth: true }

        // Bildirimler düğmesi
        Card {
            Layout.fillWidth: true
            implicitHeight: 48
            radius: 16
            color: Ui.notifCenterOpen ? Theme.accent : Theme.glass
            Behavior on color { ColorAnimation { duration: Theme.normal } }
            Accessible.role: Accessible.Button
            Accessible.name: "Bildirimler: " + Notifs.count

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 10
                Icon {
                    name: Notifs.dnd ? "bell-off" : "bell"
                    color: Ui.notifCenterOpen ? Theme.accentInk : Theme.paper
                    size: 16
                }
                Text {
                    Layout.fillWidth: true
                    text: Notifs.dnd ? "Rahatsız etme" : "Bildirimler"
                    color: Ui.notifCenterOpen ? Theme.accentInk : Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 13
                }
                Rectangle {
                    visible: Notifs.count > 0
                    implicitWidth: Math.max(22, countText.implicitWidth + 12)
                    implicitHeight: 22
                    radius: 11
                    color: Ui.notifCenterOpen ? Theme.accentInk : Theme.accent
                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: Notifs.count
                        color: Ui.notifCenterOpen ? Theme.accent : Theme.accentInk
                        font.family: Theme.mono
                        font.pixelSize: 11
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Ui.notifCenterOpen = !Ui.notifCenterOpen
            }
        }

        Item { Layout.fillHeight: true }

        SidebarStatus { Layout.fillWidth: true }
    }
}

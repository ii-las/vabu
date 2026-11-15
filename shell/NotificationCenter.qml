import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    visible: Ui.notifCenterOpen
    color: "transparent"

    readonly property bool onRight: Config.sidebarSide === "right"
    anchors { top: true; bottom: true; left: !onRight; right: onRight }
    margins { top: Theme.gap; bottom: Theme.gap; left: onRight ? 0 : Theme.gap; right: onRight ? Theme.gap : 0 }
    implicitWidth: 400
    exclusionMode: ExclusionMode.Normal

    WlrLayershell.namespace: "vabu-notification-center"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Card {
        anchors.fill: parent
        strong: true
        radius: Theme.radiusPanel
        marks: true

        Keys.onEscapePressed: Ui.notifCenterOpen = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Bildirimler"
                    color: Theme.paper
                    font.family: Theme.serif
                    font.pixelSize: 34
                }
                IconButton { icon: "close"; tooltip: "Kapat"; onClicked: Ui.notifCenterOpen = false }
            }

            // Rahatsız etme
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 16
                color: Qt.rgba(1, 1, 1, 0.05)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    Icon { name: Notifs.dnd ? "bell-off" : "bell"; size: 16 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        spacing: 0
                        Text { text: "Rahatsız etme"; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 14 }
                        Text { text: "Kritik olanlar yine görünür"; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 11 }
                    }
                    Toggle { checked: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.dash }

            // Liste
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ColumnLayout {
                    width: root.implicitWidth - 44
                    spacing: 8
                    Repeater {
                        model: Notifs.all.slice().reverse()
                        delegate: NotificationCard {
                            required property var modelData
                            Layout.fillWidth: true
                            notif: modelData
                        }
                    }
                    Text {
                        visible: Notifs.count === 0
                        Layout.topMargin: 40
                        Layout.alignment: Qt.AlignHCenter
                        text: "Her şey sakin."
                        color: Theme.muted
                        font.family: Theme.serif
                        font.italic: true
                        font.pixelSize: 26
                    }
                }
            }

            Rectangle {
                visible: Notifs.count > 0
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 22
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.16)
                Text {
                    anchors.centerIn: parent
                    text: "Tümünü temizle"
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 14
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
            }
        }
    }
}

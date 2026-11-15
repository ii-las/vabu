import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    visible: Ui.sessionMenuOpen
    color: Qt.rgba(12 / 255, 13 / 255, 18 / 255, 0.55)
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "vabu-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int selected: 0
    onVisibleChanged: if (visible) { selected = 0; row.forceActiveFocus() }

    readonly property var actions: [
        { icon: "lock",    label: "Kilitle",        run: () => Ui.lock() },
        { icon: "logout",  label: "Oturumu kapat",  run: () => Niri.quit() },
        { icon: "moon",    label: "Uyku",           run: () => { Ui.lock(); Ui.run(["systemctl", "suspend"]) } },
        { icon: "restart", label: "Yeniden başlat", run: () => Ui.run(["systemctl", "reboot"]) },
        { icon: "power",   label: "Kapat",          run: () => Ui.run(["systemctl", "poweroff"]), danger: true }
    ]

    function activate(i) {
        Ui.sessionMenuOpen = false
        actions[i].run()
    }

    MouseArea { anchors.fill: parent; onClicked: Ui.sessionMenuOpen = false }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 28

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Görüşmek üzere"
            color: Theme.paper
            font.family: Theme.serif
            font.italic: true
            font.pixelSize: 52
        }

        RowLayout {
            id: row
            spacing: 12
            focus: true
            Keys.onPressed: event => {
                const n = root.actions.length
                if (event.key === Qt.Key_Escape) Ui.sessionMenuOpen = false
                else if (event.key === Qt.Key_Left) root.selected = (root.selected - 1 + n) % n
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.selected = (root.selected + 1) % n
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activate(root.selected)
                else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) root.activate(event.key - Qt.Key_1)
                event.accepted = true
            }

            Repeater {
                model: root.actions
                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool on: root.selected === index
                    implicitWidth: 156
                    implicitHeight: 156
                    radius: 28
                    color: on ? (modelData.danger ? Theme.coral : Theme.accent) : Theme.glassStrong
                    border.color: Theme.line
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.label

                    Text {
                        anchors { left: parent.left; top: parent.top; margins: 16 }
                        text: "0" + (btn.index + 1)
                        color: btn.on ? (btn.modelData.danger ? "#3B1414" : Theme.accentInk) : Theme.muted
                        font.family: Theme.mono
                        font.pixelSize: 11
                    }
                    Icon {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -12
                        name: btn.modelData.icon
                        size: 30
                        color: btn.on ? (btn.modelData.danger ? "#3B1414" : Theme.accentInk) : Theme.paper
                    }
                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 20 }
                        text: btn.modelData.label
                        color: btn.on ? (btn.modelData.danger ? "#3B1414" : Theme.accentInk) : Theme.paper
                        font.family: Theme.serif
                        font.pixelSize: 20
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selected = btn.index
                        onClicked: root.activate(btn.index)
                    }
                }
            }
        }
    }
}

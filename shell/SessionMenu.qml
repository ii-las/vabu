import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Oturum menüsü: kilitle, uyku, oturumu kapat, yeniden başlat, kapat.
OverlayWindow {
    id: root
    open: Ui.sessionMenuOpen
    dim: 0.5
    onDismissed: Ui.sessionMenuOpen = false
    WlrLayershell.namespace: "vabu-session"

    property int selected: 0
    onOpenChanged: if (open) { selected = 0; keys.forceActiveFocus() }

    readonly property var actions: [
        { icon: "lock",               label: Lang.t("Kilitle"),        run: () => Ui.lock() },
        { icon: "bedtime",            label: Lang.t("Uyku"),           run: () => { Ui.suspend() } },
        { icon: "logout",             label: Lang.t("Oturumu kapat"),  run: () => Niri.quit() },
        { icon: "restart_alt",        label: Lang.t("Yeniden başlat"), run: () => Ui.run(["systemctl", "reboot"]) },
        { icon: "power_settings_new", label: Lang.t("Kapat"),          run: () => Ui.run(["systemctl", "poweroff"]), danger: true }
    ]

    function activate(i) {
        Ui.sessionMenuOpen = false
        actions[i].run()
    }

    Card {
        id: panel
        tint: Theme.panelDeep
        radius: Theme.radiusPanel
        shadow: true
        width: row.implicitWidth + 28
        height: row.implicitHeight + 28
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        opacity: Math.min(1, root.shown * 1.5)
        transform: Scale {
            origin.x: panel.width / 2; origin.y: panel.height / 2
            xScale: 0.95 + 0.05 * root.shown; yScale: 0.95 + 0.05 * root.shown
        }

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                const n = root.actions.length
                if (event.key === Qt.Key_Escape) Ui.sessionMenuOpen = false
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.selected = (root.selected - 1 + n) % n
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.selected = (root.selected + 1) % n
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activate(root.selected)
                event.accepted = true
            }
        }

        RowLayout {
            id: row
            x: 14
            y: 14
            spacing: 8

            Repeater {
                model: root.actions
                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool isOn: root.selected === index
                    readonly property bool danger: modelData.danger === true
                    readonly property color fg: isOn ? (danger ? (Theme.dark ? "#3A1512" : "#FFFFFF") : Theme.accentInk) : Theme.paper
                    // sırayla belirme: açılış ilerledikçe her düğme biraz gecikmeli gelir
                    readonly property real t: Math.max(0, Math.min(1, root.shown * 1.7 - index * 0.11))

                    implicitWidth: 124
                    implicitHeight: 118
                    radius: Theme.radiusTile
                    color: isOn ? (danger ? Theme.danger : Theme.accent) : Theme.well
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    opacity: t
                    transform: Translate { y: 10 * (1 - btn.t) }
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.label

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 28
                        name: btn.modelData.icon
                        size: 28
                        filled: btn.isOn
                        color: btn.fg
                    }
                    Text { textFormat: Text.PlainText;
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 20
                        text: btn.modelData.label
                        color: btn.fg
                        font.family: Theme.sans
                        font.pixelSize: Math.round((13) * Config.textScale)
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: root.selected = btn.index
                        onClicked: root.activate(btn.index)
                    }
                }
            }
        }

    }
}

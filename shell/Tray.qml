import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
Card {
    id: root
    property var hostWindow
    visible: SystemTray.items.values.length > 0
    implicitHeight: flow.implicitHeight + 16
    Flow {
        id: flow
        x: 8; y: 8
        width: parent.width - 16
        spacing: 4
        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: button
                required property var modelData
                width: 32; height: 32
                Controls.ToolTip.visible: mouse.containsMouse
                Controls.ToolTip.text: modelData.tooltipTitle || modelData.title || modelData.id
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: modelData.tooltipTitle || modelData.title || modelData.id
                function menu() {
                    const pos = mapToItem(null, 0, height)
                    if (modelData.hasMenu) modelData.display(root.hostWindow, Math.round(pos.x), Math.round(pos.y))
                }
                Keys.onReturnPressed: modelData.onlyMenu ? menu() : modelData.activate()
                Keys.onSpacePressed: menu()
                Rectangle { anchors.fill: parent; radius: 10; color: mouse.containsMouse || button.activeFocus ? Theme.hover : "transparent" }
                IconImage { anchors.centerIn: parent; implicitSize: 22; source: button.modelData.icon }
                MouseArea {
                    id: mouse; anchors.fill: parent; hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event.button === Qt.RightButton || button.modelData.onlyMenu) button.menu()
                        else if (event.button === Qt.MiddleButton) button.modelData.secondaryActivate()
                        else button.modelData.activate()
                    }
                    onWheel: event => button.modelData.scroll(event.angleDelta.y, false)
                }
            }
        }
    }
}

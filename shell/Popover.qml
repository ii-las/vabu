import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Yan panelden açılan paneller için ekran başına tek pencere. Panel, yan panelin hemen
// yanında belirir; içerik değişince çerçeve yeni boyuta akarak geçer. Dışına tıklamak ya da
// Esc kapatır.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property string screenName: screen?.name ?? ""
    readonly property bool open: Ui.popover !== "" && Ui.popoverScreen === screenName
    readonly property bool onRight: Config.sidebarSide === "right"
    // Kapanırken içerik bir an daha yerinde kalsın
    property string current: ""
    readonly property bool top: current === "calendar"

    readonly property var sources: ({
        "wifi": "PanelWifi.qml",
        "bluetooth": "PanelBluetooth.qml",
        "sound": "PanelSound.qml",
        "calendar": "PanelCalendar.qml",
        "control": "PanelControl.qml",
        "notifications": "PanelNotifications.qml"
    })

    property real shown: open ? 1 : 0
    Behavior on shown {
        NumberAnimation {
            duration: root.open ? Theme.enter : Theme.exit
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.open ? Theme.emphasized : Theme.accelerate
        }
    }

    onOpenChanged: if (open) sync()
    Connections {
        target: Ui
        function onPopoverChanged() { if (root.open) root.sync() }
    }
    function sync() {
        if (current === Ui.popover) return
        if (shown > 0.05 && current !== "") swap.restart()
        else current = Ui.popover
    }

    visible: open || shown > 0.001
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    // Yan paneli örtmez: panel açıkken başka bir düğmeye tek tıkla geçilebilsin
    readonly property real inset: Theme.sidebarNow - Theme.gap
    margins { left: onRight ? 0 : inset; right: onRight ? inset : 0 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "vabu-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: Ui.closePopover()
    }

    Card {
        id: frame
        tint: Theme.panelDeep
        radius: Theme.radiusPanel
        shadow: true

        width: Math.min(400, root.width - 2 * Theme.gap)
        height: Math.min(root.height - 2 * Theme.gap, (loader.item ? loader.item.implicitHeight : 120) + 2 * Theme.pad)
        originX: root.onRight ? 0 : root.inset
        x: root.onRight ? root.width - Theme.gap - width : Theme.gap
        y: root.top ? Theme.gap : root.height - Theme.gap - height
        Behavior on height {
            enabled: root.shown > 0.9
            NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
        }

        opacity: Math.min(1, root.shown * 1.4)
        transform: [
            Scale {
                origin.x: root.onRight ? frame.width : 0
                origin.y: root.top ? 0 : frame.height
                xScale: 0.985 + 0.015 * root.shown
                yScale: 0.985 + 0.015 * root.shown
            },
            Translate { x: (root.onRight ? 1 : -1) * 8 * (1 - root.shown) }
        ]

        // panelin içine tıklamak kapatmasın
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: Theme.pad
            clip: true
            focus: true
            Keys.onEscapePressed: Ui.closePopover()

            Loader {
                id: loader
                width: parent.width
                source: root.current !== "" ? root.sources[root.current] : ""
                onLoaded: if (item && item.forceActiveFocus) body.forceActiveFocus()
            }
        }

        // Panelden panele geçiş: içerik kısa bir solmayla değişir
        SequentialAnimation {
            id: swap
            NumberAnimation { target: body; property: "opacity"; to: 0; duration: Config.reducedMotion ? 0 : 90 }
            ScriptAction { script: root.current = Ui.popover }
            NumberAnimation { target: body; property: "opacity"; to: 1; duration: Config.reducedMotion ? 0 : 200; easing.type: Easing.OutCubic }
        }
    }

    onVisibleChanged: {
        if (!visible) { current = ""; body.opacity = 1 }
        else body.forceActiveFocus()
    }
}

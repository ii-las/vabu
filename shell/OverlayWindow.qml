import QtQuick
import Quickshell
import Quickshell.Wayland

// Tam ekran katmanlar (başlatıcı, oturum menüsü, kısayollar) için ortak pencere:
// arka planı hafifçe karartır, dışarı tıklayınca kapanır, açılıp kapanırken `shown` 0-1 arasında akar.
PanelWindow {
    id: root
    property bool open: false
    property real dim: 0.34
    signal dismissed()
    default property alias content: holder.data

    property real shown: open ? 1 : 0
    Behavior on shown {
        NumberAnimation {
            duration: root.open ? Theme.enter : Theme.exit
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.open ? Theme.emphasized : Theme.accelerate
        }
    }

    visible: open || shown > 0.001
    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Theme.dark ? Qt.rgba(0, 0, 0, root.dim * Math.min(1, root.shown * 1.5)) : Qt.rgba(30 / 255, 40 / 255, 60 / 255, 0.7 * root.dim * Math.min(1, root.shown * 1.5))
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.dismissed()
    }
    onOpenChanged: if (open) Qt.callLater(() => { if (root.open && !holder.activeFocus) holder.forceActiveFocus(Qt.PopupFocusReason) })
    FocusScope {
        id: holder
        anchors.fill: parent
        focus: root.open
        // Child controls receive keys first; Escape bubbles here from any child.
        Keys.priority: Keys.AfterItem
        Keys.onEscapePressed: event => { event.accepted = true; root.dismissed() }
    }
}

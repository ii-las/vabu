import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Yan panel: saat, çalışma alanları, uygulamalar, medya, durum.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property bool onRight: Config.sidebarSide === "right"
    readonly property string screenName: screen?.name ?? ""
    readonly property real originX: onRight ? (screen?.width ?? 0) - width : 0

    anchors {
        top: true
        bottom: true
        left: !onRight
        right: onRight
    }
    // Dar görünüme geçerken içerik söner, genişlik değişir (niri pencereleri kaydırır), sonra yeni içerik belirir
    property bool compact: Config.sidebarCompact
    property real fade: 1
    Connections {
        target: Config
        function onSidebarCompactChanged() { if (root.compact !== Config.sidebarCompact) switcher.restart() }
    }
    SequentialAnimation {
        id: switcher
        NumberAnimation { target: root; property: "fade"; to: 0; duration: Config.reducedMotion ? 0 : 110; easing.type: Easing.InCubic }
        ScriptAction { script: root.compact = Config.sidebarCompact }
        NumberAnimation { target: root; property: "fade"; to: 1; duration: Config.reducedMotion ? 0 : 280; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
    }

    implicitWidth: compact ? Theme.sidebarCompactWidth : Theme.sidebarWidth
    // Pencerelerle kartlar arasındaki boşluğu niri'nin kendi aralığı verir
    exclusiveZone: implicitWidth - Theme.gap
    color: "transparent"

    WlrLayershell.namespace: "vabu-sidebar"
    WlrLayershell.layer: WlrLayer.Top

    // Boş yere tıklamak açık paneli kapatır
    MouseArea {
        anchors.fill: parent
        onPressed: Ui.closePopover()
    }

    Flickable {
        id: scroller
        anchors.fill: parent
        anchors.margins: Theme.gap
        clip: true
        contentHeight: root.compact ? compactView.implicitHeight : fullView.implicitHeight
        opacity: root.fade
        transform: Translate { x: (1 - root.fade) * (root.onRight ? 12 : -12) }

        ColumnLayout {
            id: fullView
            width: parent.width
            height: Math.max(scroller.height, implicitHeight)
            visible: !root.compact
            spacing: 8

            SidebarClock {
                Layout.fillWidth: true
                originX: root.originX
                screenName: root.screenName
            }
            SidebarWorkspaces {
                Layout.fillWidth: true
                originX: root.originX
                output: root.screenName
            }
            SidebarApps {
                Layout.fillWidth: true
                originX: root.originX
            }

            Tray { Layout.fillWidth: true; originX: root.originX; hostWindow: root }
            Item { Layout.fillHeight: true }

            SidebarMedia {
                Layout.fillWidth: true
                originX: root.originX
            }
            SidebarStatus {
                Layout.fillWidth: true
                originX: root.originX
                screenName: root.screenName
            }
        }

        SidebarCompact {
            id: compactView
            width: parent.width
            height: Math.max(scroller.height, implicitHeight)
            visible: root.compact
            originX: root.originX
            screenName: root.screenName
            hostWindow: root
        }
    }
}

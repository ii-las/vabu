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
    implicitWidth: Theme.sidebarWidth
    // Pencerelerle kartlar arasındaki boşluğu niri'nin kendi aralığı verir
    exclusiveZone: Theme.sidebarWidth - Theme.gap
    color: "transparent"

    WlrLayershell.namespace: "vabu-sidebar"
    WlrLayershell.layer: WlrLayer.Top

    // Boş yere tıklamak açık paneli kapatır
    MouseArea {
        anchors.fill: parent
        onPressed: Ui.closePopover()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.gap
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
}

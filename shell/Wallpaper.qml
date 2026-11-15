import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    color: Theme.night
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "vabu-wallpaper"
    WlrLayershell.layer: WlrLayer.Background

    property string current: Config.wallpaper
    onCurrentChanged: { next.source = current }

    Image {
        id: shown
        anchors.fill: parent
        source: root.current
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
    }
    Image {
        id: next
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
        opacity: 0
        onStatusChanged: if (status === Image.Ready) fade.start()
        NumberAnimation on opacity {
            id: fade
            running: false
            from: 0; to: 1
            duration: Theme.slow
            onFinished: { shown.source = next.source; next.opacity = 0 }
        }
    }
}

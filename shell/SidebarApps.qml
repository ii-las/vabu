import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Card {
    id: root
    implicitHeight: grid.implicitHeight + 24

    function isRunning(entry) {
        const id = entry.id.toLowerCase().replace(/\.desktop$/, "")
        return Niri.windows.some(w => {
            const a = (w.app_id || "").toLowerCase()
            return a === id || id.endsWith("." + a) || a.endsWith("." + id)
        })
    }

    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.margins: 12
        columns: 4
        rowSpacing: 8
        columnSpacing: 8

        // Ara
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 14
            color: Theme.mint
            Icon { anchors.centerIn: parent; name: "search"; color: Theme.mintInk; size: 20; stroke: 2 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.openLauncher("search") }
            Accessible.role: Accessible.Button
            Accessible.name: "Ara"
        }

        Repeater {
            model: Apps.pinnedEntries.slice(0, 6)
            delegate: Rectangle {
                id: cell
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 14
                color: mouse.containsMouse ? Theme.stoneHi : "#24242B"
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                Accessible.role: Accessible.Button
                Accessible.name: modelData.name

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 28
                    source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                }
                Rectangle {
                    visible: root.isRunning(cell.modelData)
                    width: 4; height: 4; radius: 2
                    color: Theme.paper
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Apps.launch(cell.modelData)
                }
            }
        }

        // Sabitle (Ayarlar > Görünüm'den düzenlenir)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 14
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.22)
            border.width: 1
            Icon { anchors.centerIn: parent; name: "plus"; color: Theme.muted; size: 18 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.settings("look") }
            Accessible.role: Accessible.Button
            Accessible.name: "Sabitlenenleri düzenle"
        }
    }
}

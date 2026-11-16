import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Arama girişi ve sabitlenmiş uygulamalar.
Card {
    id: root
    implicitHeight: col.implicitHeight + 16

    ColumnLayout {
        id: col
        x: 8
        y: 8
        width: parent.width - 16
        spacing: 6

        // Ara
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: Theme.radiusRow
            color: searchMouse.pressed ? Theme.pressed : searchMouse.containsMouse ? Theme.hover : Theme.well
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Accessible.role: Accessible.Button
            Accessible.name: Lang.t("Ara ve başlat")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 13
                anchors.rightMargin: 12
                spacing: 10
                Icon { name: "search"; size: 19; color: Theme.soft }
                Text { textFormat: Text.PlainText;
                    Layout.fillWidth: true
                    text: Lang.t("Ara")
                    color: Theme.muted
                    font.family: Theme.sans
                    font.pixelSize: Math.round((14) * Config.textScale)
                }
            }
            MouseArea {
                id: searchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Ui.openLauncher("search")
            }
        }

        // Sabitlenenler (Ayarlar > Görünüm'den düzenlenir)
        Flow {
            id: dock
            Layout.fillWidth: true
            visible: Apps.pinnedEntries.length > 0
            readonly property real cell: Math.floor(width / 6)

            Repeater {
                model: Apps.pinnedEntries.slice(0, 12)
                delegate: Item {
                    id: app
                    required property var modelData
                    readonly property bool isRunning: Apps.windowsOf(modelData).length > 0
                    width: dock.cell
                    height: 44
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name

                    Rectangle {
                        anchors.centerIn: parent
                        width: 38; height: 38
                        radius: 12
                        color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }
                    IconImage {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        implicitSize: 26
                        source: Quickshell.iconPath(app.modelData.icon, "application-x-executable")
                        scale: mouse.pressed ? 0.88 : mouse.containsMouse ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                    }
                    Rectangle {
                        width: app.isRunning ? 10 : 0
                        height: 3; radius: 1.5
                        opacity: app.isRunning ? 1 : 0
                        color: Theme.paper
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        Behavior on width { NumberAnimation { duration: Theme.state; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                        Behavior on opacity { NumberAnimation { duration: Theme.state } }
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        // orta tuş: açık olsa da yeni pencere
                        onClicked: e => e.button === Qt.RightButton ? Ui.appMenu(app.modelData) : e.button === Qt.MiddleButton ? Apps.launch(app.modelData) : Apps.open(app.modelData)
                    }
                }
            }
        }
    }
}

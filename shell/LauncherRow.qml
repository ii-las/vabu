import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Başlatıcı satırı: uygulama, komut ya da kurulabilir paket.
Item {
    id: root
    property string mode: "search"
    property var item: ({})
    property bool selected: false
    signal activated()
    signal hovered()

    readonly property bool isInstall: mode === "install"
    readonly property string state_: isInstall && item.key ? (Packages.states[item.key] ?? (item.installed ? "installed" : "")) : ""
    readonly property string sub: mode === "search" ? (item.genericName || item.comment || "")
        : mode === "command" ? (item.sub ?? "") : (item.summary || "")

    implicitHeight: 52

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.hovered()
        onClicked: root.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Item {
            implicitWidth: 32
            implicitHeight: 32
            IconImage {
                visible: root.mode === "search"
                anchors.centerIn: parent
                implicitSize: 30
                source: root.mode === "search" ? Quickshell.iconPath(root.item.icon, "application-x-executable") : ""
            }
            Rectangle {
                visible: root.mode !== "search"
                anchors.fill: parent
                radius: 10
                color: Theme.well
                Icon {
                    anchors.centerIn: parent
                    name: root.mode === "command" ? (root.item.icon ?? "") : "deployed_code"
                    size: 19
                    color: Theme.soft
                }
            }
        }

        Text {
            Layout.maximumWidth: root.width * 0.5
            text: root.item.name ?? ""
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: 15
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: root.sub
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        // Kaynaklar: tıklayınca o kaynaktan kurar
        Repeater {
            model: root.isInstall ? (root.item.sources ?? []) : []
            delegate: Rectangle {
                id: src
                required property var modelData
                readonly property var info: Packages.sourceInfo[modelData.kind]
                implicitHeight: 24
                implicitWidth: badge.implicitWidth + 16
                radius: 8
                color: srcMouse.containsMouse ? Theme.hover : Theme.well
                Row {
                    id: badge
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle { width: 5; height: 5; radius: 2.5; color: src.info.color; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: src.info.label
                        color: Theme.soft
                        font.family: Theme.sans
                        font.pixelSize: 11.5
                        font.weight: Font.Medium
                    }
                }
                MouseArea {
                    id: srcMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.state_ === ""
                    onClicked: Packages.install(root.item, src.modelData)
                }
            }
        }

        Spinner { visible: root.state_ === "installing"; size: 17 }
        Text {
            visible: root.isInstall && root.state_ !== ""
            text: ({ "installed": "Kurulu", "done": "Kuruldu", "installing": "Kuruluyor", "error": "Kurulamadı" })[root.state_] ?? ""
            color: root.state_ === "error" ? Theme.danger : root.state_ === "done" ? Theme.ok : Theme.muted
            font.family: Theme.sans
            font.pixelSize: 12.5
            font.weight: Font.Medium
        }

        Text {
            visible: root.selected && !(root.isInstall && root.state_ !== "" && root.state_ !== "error")
            text: root.isInstall ? "Kur  ⏎" : root.mode === "command" ? "Çalıştır  ⏎" : "Aç  ⏎"
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: 12
        }
    }
}

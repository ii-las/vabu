import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root
    property string mode: "search"
    property var item: ({})
    property bool selected: false
    signal activated()
    property int order: 0          // sıralı giriş animasyonu için
    signal hovered()

    readonly property bool isInstall: mode === "install"
    readonly property string state_: isInstall && item.key ? (Packages.states[item.key] ?? (item.installed ? "installed" : "")) : ""

    implicitHeight: 64
    radius: 16
    color: selected ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 14

        // Simge
        Rectangle {
            implicitWidth: 38
            implicitHeight: 38
            radius: 11
            color: Qt.rgba(1, 1, 1, 0.06)
            IconImage {
                visible: root.mode === "search"
                anchors.centerIn: parent
                implicitSize: 28
                source: root.mode === "search" ? Quickshell.iconPath(root.item.icon, "application-x-executable") : ""
            }
            Icon {
                visible: root.mode === "command"
                anchors.centerIn: parent
                name: root.mode === "command" ? (root.item.icon ?? "") : ""
                color: Theme.paper
            }
            Text {
                visible: root.isInstall
                anchors.centerIn: parent
                text: root.isInstall && root.item.name ? root.item.name.charAt(0).toUpperCase() : ""
                color: Theme.sky
                font.family: Theme.serif
                font.pixelSize: 22
            }
        }

        // Ad + açıklama
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: root.item.name ?? ""
                color: Theme.paper
                font.family: Theme.sans
                font.pixelSize: 15
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.mode === "search" ? (root.item.genericName || root.item.comment || "")
                    : root.mode === "command" ? root.item.sub : (root.item.summary || "")
                color: Theme.muted
                font.family: Theme.sans
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        // Kaynak rozetleri (tıklayınca o kaynaktan kurar)
        Repeater {
            model: root.isInstall ? (root.item.sources ?? []) : []
            delegate: Rectangle {
                required property var modelData
                readonly property var info: Packages.sourceInfo[modelData.kind]
                implicitHeight: 22
                implicitWidth: badge.implicitWidth + 16
                radius: 11
                color: "transparent"
                border.color: info.color
                Text {
                    id: badge
                    anchors.centerIn: parent
                    text: parent.info.label
                    color: parent.info.color
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.letterSpacing: 0.6
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.state_ === ""
                    onClicked: Packages.install(root.item, parent.modelData)
                }
            }
        }

        // Eylem
        Rectangle {
            visible: root.isInstall
            implicitWidth: Math.max(64, action.implicitWidth + 28)
            implicitHeight: 34
            radius: 17
            color: root.state_ === "installed" || root.state_ === "done" ? "transparent"
                 : root.state_ === "error" ? Theme.coral
                 : root.selected ? Theme.mint : Qt.rgba(1, 1, 1, 0.1)
            Text {
                id: action
                anchors.centerIn: parent
                text: ({ "installed": "Kurulu", "done": "Kuruldu", "installing": "Kuruluyor…", "error": "Tekrar dene" })[root.state_] ?? "Kur"
                color: root.state_ === "installed" || root.state_ === "done" ? Theme.muted
                     : root.state_ === "error" ? "#3B1414"
                     : root.selected ? Theme.mintInk : Theme.paper
                font.family: Theme.sans
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.activated()
    }

    opacity: 0
    transform: Translate { id: shift; y: 8 }
    // order < 0: animasyonsuz (yazarken sonuçlar her tuşta yeniden kurulur)
    Component.onCompleted: { if (order < 0) { opacity = 1; shift.y = 0 } else appear.start() }
    SequentialAnimation {
        id: appear
        PauseAnimation { duration: Math.min(root.order, 8) * 28 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: shift; property: "y"; to: 0; duration: 240; easing.type: Easing.OutCubic }
        }
    }
}

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
    signal contextRequested()

    readonly property bool isInstall: mode === "install"
    readonly property string state_: isInstall && item.key ? (Packages.states[item.key] ?? (item.installed ? "installed" : "")) : ""
    readonly property string sub: isInstall && (state_ === "installing" || state_ === "error") ? (Packages.messages[item.key] || "") : mode === "search" ? (item.genericName || item.comment || "")
        : mode === "command" ? (item.sub ?? "") : (item.summary || "")

    implicitHeight: 52

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.hovered()
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton && root.mode === "search" ? Ui.appMenu(root.item) : root.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Item {
            implicitWidth: 32
            implicitHeight: 32
            // Kur kipinde simge AppStream önbelleğinden (dosya yolu) ya da temadan gelir
            readonly property string pkgIcon: !root.isInstall || !root.item.icon ? ""
                : root.item.icon.startsWith("/") ? "file://" + root.item.icon
                : Quickshell.iconPath(root.item.icon, true)
            readonly property string source: (root.mode === "search" || root.mode === "windows") ? Quickshell.iconPath(root.item.icon, "application-x-executable") : pkgIcon
            IconImage {
                id: appIcon
                visible: parent.source !== "" && status !== Image.Error
                anchors.centerIn: parent
                implicitSize: 30
                source: parent.source
            }
            Rectangle {
                visible: !appIcon.visible
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

        Text { textFormat: Text.PlainText;
            Layout.maximumWidth: root.width * 0.5
            text: root.item.name ?? ""
            color: Theme.paper
            font.family: Theme.sans
            font.pixelSize: Math.round((15) * Config.textScale)
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text { textFormat: Text.PlainText;
            Layout.fillWidth: true
            text: root.sub
            color: Theme.muted
            font.family: Theme.sans
            font.pixelSize: Math.round((13) * Config.textScale)
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
                    Text { textFormat: Text.PlainText;
                        text: src.info.label
                        color: Theme.soft
                        font.family: Theme.sans
                        font.pixelSize: Math.round((12) * Config.textScale)
                        font.weight: Font.Medium
                    }
                }
                MouseArea {
                    id: srcMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !Packages.installing && (root.state_ === "" || root.state_ === "error")
                    onClicked: Packages.install(root.item, src.modelData)
                }
            }
        }

        Spinner { visible: root.state_ === "installing"; size: 17 }
        Text { textFormat: Text.PlainText;
            visible: root.isInstall && root.state_ !== ""
            text: ({ "installed": Lang.t("Kurulu"), "done": Lang.t("Kuruldu"), "installing": Lang.t("Kuruluyor"), "error": Lang.t("Kurulamadı") })[root.state_] ?? ""
            color: root.state_ === "error" ? Theme.danger : root.state_ === "done" ? Theme.ok : Theme.muted
            font.family: Theme.sans
            font.pixelSize: Math.round((12) * Config.textScale)
            font.weight: Font.Medium
        }

    }
}

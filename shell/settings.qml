//@ pragma UseQApplication
// Vabu Ayarlar - giriş noktası.  Çalıştırma:  vabu-settings [sayfa]
// Sayfalar: look display network sound drivers apps updates keyboard users about
// Zaten açıksa:  qs -p /usr/share/vabu/shell/settings.qml ipc call settings open <sayfa>
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    readonly property var pages: [
        { key: "look",     icon: "palette",           title: "Görünüm",                    file: "SettingsLook.qml" },
        { key: "display",  icon: "desktop_windows",   title: "Ekranlar",                   file: "SettingsDisplays.qml" },
        { key: "network",  icon: "wifi",              title: "Ağ ve Bluetooth",            file: "SettingsNetwork.qml" },
        { key: "sound",    icon: "volume_up",         title: "Ses",                        file: "SettingsSound.qml" },
        { key: "keyboard", icon: "keyboard",          title: "Klavye ve dokunmatik yüzey", file: "SettingsKeyboard.qml" },
        { key: "apps",     icon: "apps",              title: "Uygulamalar ve kaynaklar",   file: "SettingsApps.qml" },
        { key: "updates",  icon: "system_update_alt", title: "Güncellemeler",              file: "SettingsUpdates.qml" },
        { key: "drivers",  icon: "memory",            title: "Sürücüler",                  file: "SettingsDrivers.qml" },
        { key: "users",    icon: "group",             title: "Kullanıcılar",               file: "SettingsUsers.qml" },
        { key: "about",    icon: "info",              title: "Hakkında",                   file: "SettingsAbout.qml" }
    ]
    property string page: {
        const p = Quickshell.env("VABU_SETTINGS_PAGE") || "look"
        return pages.some(x => x.key === p) ? p : "look"
    }
    property string search: ""
    readonly property int pageIndex: Math.max(0, pages.findIndex(p => p.key === page))

    // Güncelleme sayısı (gezinmedeki rozet)
    property int updateCount: 0
    Process {
        running: true
        command: ["sh", "-c", "dnf check-upgrade -q -C 2>/dev/null | grep -cE '^[A-Za-z0-9_.+-]+\\.(x86_64|aarch64|noarch|i686)\\s'"]
        stdout: StdioCollector { onStreamFinished: root.updateCount = parseInt(text) || 0 }
    }

    IpcHandler {
        target: "settings"
        function open(page: string): void {
            if (root.pages.some(x => x.key === page)) root.page = page
        }
    }

    FloatingWindow {
        id: win
        title: "Vabu Ayarlar"
        implicitWidth: 1080
        implicitHeight: 780
        color: Theme.panelSolid
        onVisibleChanged: if (!visible) Qt.quit()

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Gezinme
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 264
                color: Qt.rgba(1, 1, 1, 0.028)

                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.line }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.topMargin: 20
                    spacing: 12

                    Text {
                        Layout.leftMargin: 10
                        text: "Ayarlar"
                        color: Theme.paper
                        font.family: Theme.sans
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        font.letterSpacing: -0.2
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Theme.radiusRow
                        color: searchInput.activeFocus ? Qt.rgba(1, 1, 1, 0.08) : Theme.well
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        Icon { x: 11; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 18; color: Theme.muted }
                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            anchors.leftMargin: 38
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.paper
                            font.family: Theme.sans
                            font.pixelSize: 14
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentInk
                            clip: true
                            onTextChanged: root.search = text.toLowerCase()
                            Text {
                                visible: !searchInput.text
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Ara"
                                color: Theme.faint
                                font: searchInput.font
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: nav.implicitHeight

                        // Seçili sayfanın zemini: sayfadan sayfaya kayar
                        Rectangle {
                            visible: !root.search
                            y: root.pageIndex * 42
                            width: parent.width
                            height: 40
                            radius: Theme.radiusRow
                            color: Theme.accent
                            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                        }

                        Column {
                            id: nav
                            width: parent.width
                            spacing: 2
                            Repeater {
                                model: root.pages
                                delegate: Item {
                                    id: navItem
                                    required property var modelData
                                    required property int index
                                    readonly property bool isOn: root.page === modelData.key
                                    readonly property bool match: !root.search || modelData.title.toLowerCase().includes(root.search)
                                    readonly property color fg: isOn ? Theme.accentInk : Theme.paper
                                    width: nav.width
                                    height: 40
                                    visible: match
                                    Accessible.role: Accessible.PageTab
                                    Accessible.name: modelData.title

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.radiusRow
                                        // arama sırasında kayan zemin gizlidir; seçili satır kendi zeminini çizer
                                        color: navItem.isOn ? (root.search ? Theme.accent : "transparent")
                                            : mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : "transparent"
                                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                                    }
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 10
                                        spacing: 12
                                        Icon { name: navItem.modelData.icon; size: 19; color: navItem.fg; filled: navItem.isOn }
                                        Text {
                                            Layout.fillWidth: true
                                            text: navItem.modelData.title
                                            color: navItem.fg
                                            font.family: Theme.sans
                                            font.pixelSize: 14
                                            font.weight: navItem.isOn ? Font.DemiBold : Font.Medium
                                            elide: Text.ElideRight
                                        }
                                        Rectangle {
                                            visible: navItem.modelData.key === "updates" && root.updateCount > 0
                                            implicitWidth: Math.max(20, badge.implicitWidth + 12); implicitHeight: 20; radius: 10
                                            color: navItem.isOn ? Theme.accentInk : Theme.well
                                            Text {
                                                id: badge
                                                anchors.centerIn: parent
                                                text: root.updateCount
                                                color: navItem.isOn ? Theme.accent : Theme.paper
                                                font.family: Theme.sans
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                    MouseArea {
                                        id: mouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.page = navItem.modelData.key
                                    }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // İçerik
            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: content.implicitHeight + 64
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: content
                    x: Math.max(36, (flick.width - width) / 2)
                    y: 28
                    width: Math.min(720, flick.width - 72)
                    spacing: 18

                    Text {
                        text: root.pages[root.pageIndex].title
                        color: Theme.paper
                        font.family: Theme.sans
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        font.letterSpacing: -0.4
                    }

                    Loader {
                        id: loader
                        Layout.fillWidth: true
                        source: root.pages[root.pageIndex].file
                        onSourceChanged: { flick.contentY = 0; pageIn.restart() }
                        transform: Translate { id: pageShift; y: 0 }
                        ParallelAnimation {
                            id: pageIn
                            NumberAnimation { target: loader; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                            NumberAnimation { target: pageShift; property: "y"; from: 12; to: 0; duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
                        }
                    }
                }
            }
        }
    }
}

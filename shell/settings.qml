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
        { key: "look",     title: "Görünüm",                  file: "SettingsLook.qml" },
        { key: "display",  title: "Ekranlar",                 file: "SettingsDisplays.qml" },
        { key: "network",  title: "Ağ ve Bluetooth",          file: "SettingsNetwork.qml" },
        { key: "sound",    title: "Ses",                      file: "SettingsSound.qml" },
        { key: "drivers",  title: "Sürücüler",                file: "SettingsDrivers.qml" },
        { key: "apps",     title: "Uygulamalar ve kaynaklar", file: "SettingsApps.qml" },
        { key: "updates",  title: "Güncellemeler",            file: "SettingsUpdates.qml" },
        { key: "keyboard", title: "Klavye ve dokunmatik yüzey", file: "SettingsKeyboard.qml" },
        { key: "users",    title: "Kullanıcılar",             file: "SettingsUsers.qml" },
        { key: "about",    title: "Hakkında",                 file: "SettingsAbout.qml" }
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
        implicitWidth: 1136
        implicitHeight: 820
        color: "#16161B"
        onVisibleChanged: if (!visible) Qt.quit()

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Gezinme
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 276
                color: Qt.rgba(1, 1, 1, 0.025)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    anchors.topMargin: 22
                    spacing: 14

                    Text {
                        Layout.leftMargin: 8
                        text: "Ayarlar"
                        color: Theme.paper
                        font.family: Theme.serif
                        font.pixelSize: 36
                    }
                    Field {
                        Layout.fillWidth: true
                        placeholder: "Ayarlarda ara"
                        onTextChanged: root.search = text.toLowerCase()
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Repeater {
                            model: root.pages
                            delegate: Rectangle {
                                id: navItem
                                required property var modelData
                                required property int index
                                readonly property bool isOn: root.page === modelData.key
                                readonly property bool match: !root.search || modelData.title.toLowerCase().includes(root.search)
                                Layout.fillWidth: true
                                implicitHeight: 44
                                visible: match
                                radius: Theme.radiusRow
                                color: isOn ? Theme.accent : (mouse.containsMouse ? Theme.hover : "transparent")
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                Accessible.role: Accessible.PageTab
                                Accessible.name: modelData.title

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 12
                                    Rectangle {
                                        implicitWidth: 26; implicitHeight: 20; radius: 6
                                        color: "transparent"
                                        border.color: navItem.isOn ? Qt.rgba(20 / 255, 36 / 255, 63 / 255, 0.5) : Qt.rgba(1, 1, 1, 0.2)
                                        Text {
                                            anchors.centerIn: parent
                                            text: String(navItem.index + 1).padStart(2, "0")
                                            color: navItem.isOn ? Theme.accentInk : Theme.paper
                                            font.family: Theme.mono
                                            font.pixelSize: 10
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: navItem.modelData.title
                                        color: navItem.isOn ? Theme.accentInk : Theme.paper
                                        font.family: Theme.sans
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }
                                    Rectangle {
                                        visible: navItem.modelData.key === "updates" && root.updateCount > 0
                                        implicitWidth: Math.max(20, badge.implicitWidth + 12); implicitHeight: 20; radius: 10
                                        color: Theme.mint
                                        Text { id: badge; anchors.centerIn: parent; text: root.updateCount; color: Theme.mintInk; font.family: Theme.mono; font.pixelSize: 10 }
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
                    Item { Layout.fillHeight: true }
                    Text {
                        Layout.leftMargin: 8
                        text: "VABU AYARLAR"
                        color: Theme.faint
                        font.family: Theme.mono
                        font.pixelSize: 10
                        font.letterSpacing: 1.6
                    }
                }
            }

            // İçerik
            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: content.implicitHeight + 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: content
                    x: 40
                    y: 30
                    width: flick.width - 80
                    spacing: 22

                    RowLayout {
                        spacing: 14
                        Text {
                            text: String(root.pageIndex + 1).padStart(2, "0")
                            color: Theme.muted
                            font.family: Theme.mono
                            font.pixelSize: 12
                        }
                        Text {
                            text: root.pages[root.pageIndex].title
                            color: Theme.paper
                            font.family: Theme.serif
                            font.pixelSize: 46
                        }
                    }

                    Loader {
                        id: loader
                        Layout.fillWidth: true
                        source: root.pages[root.pageIndex].file
                        onSourceChanged: { flick.contentY = 0; pageIn.restart() }
                        transform: Translate { id: pageShift; y: 0 }
                        ParallelAnimation {
                            id: pageIn
                            NumberAnimation { target: loader; property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }
                            NumberAnimation { target: pageShift; property: "y"; from: 10; to: 0; duration: 280; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}

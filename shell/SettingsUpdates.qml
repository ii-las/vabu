import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 18

    property var rpm: []              // [{name, version, repo}]
    property var flat: []             // [{id, version}]
    property bool checking: false
    property bool autoDownload: true
    property var snapshots: []

    readonly property int total: rpm.length + flat.length

    function check(refresh) {
        checking = true
        dnfCheck.command = ["sh", "-c", "dnf check-upgrade -q " + (refresh ? "--refresh" : "-C") + " 2>/dev/null; true"]
        dnfCheck.running = true
        flatCheck.running = true
    }
    Component.onCompleted: { check(false); timer.running = true; snaps.running = true }

    Process {
        id: dnfCheck
        stdout: StdioCollector {
            onStreamFinished: {
                page.rpm = text.split("\n").map(l => l.trim().split(/\s+/)).filter(p => p.length >= 3 && /\.(x86_64|aarch64|noarch|i686)$/.test(p[0]))
                    .map(p => ({ name: p[0].replace(/\.[^.]+$/, ""), version: p[1], repo: p[2] }))
                    .sort((a, b) => (b.repo.includes("vabu") - a.repo.includes("vabu")) || a.name.localeCompare(b.name))
                page.checking = false
            }
        }
    }
    Process {
        id: flatCheck
        command: ["flatpak", "remote-ls", "--updates", "--app", "--columns=application,version"]
        stdout: StdioCollector {
            onStreamFinished: page.flat = text.split("\n").filter(l => l.trim()).map(l => { const [id, version] = l.split("\t"); return { id, version: version || "" } })
        }
    }
    Process {
        id: timer
        command: ["systemctl", "is-enabled", "vabu-update.timer"]
        stdout: StdioCollector { onStreamFinished: page.autoDownload = text.trim() === "enabled" }
    }
    Process {
        id: snaps
        command: ["snapper", "-c", "root", "--jsonout", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try { list = JSON.parse(text).root || [] } catch (e) { list = [] }
                page.snapshots = list.filter(s => s.number > 0 && s.type !== "post").reverse().slice(0, 6)
            }
        }
    }

    // Özet
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 104
        radius: 20
        readonly property color tone: page.total > 0 ? Theme.mint : Theme.sky
        color: Qt.rgba(tone.r, tone.g, tone.b, 0.08)
        border.color: Qt.rgba(tone.r, tone.g, tone.b, 0.35)
        RowLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: page.checking ? "Denetleniyor…" : page.total > 0 ? page.total + " güncelleme hazır" : "Her şey güncel"
                    color: Theme.paper; font.family: Theme.serif; font.pixelSize: 34
                }
                Text {
                    text: page.total > 0 ? "Güncellemeden önce otomatik geri alma noktası oluşturulur." : "Vabu her gün arka planda denetler."
                    color: Theme.soft; font.family: Theme.sans; font.pixelSize: 13
                }
            }
            PillButton { label: "Denetle"; icon: "restart"; onClicked: page.check(true) }
            PillButton {
                visible: page.total > 0
                primary: true
                label: "Şimdi güncelle"
                onClicked: Ui.terminal(["sh", "-c", "vabu update; echo; read -p 'Kapatmak için Enter…' _"])
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 28
        rowSpacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 0
            SectionLabel { text: "Sistem paketleri · " + page.rpm.length }
            DashLine { Layout.fillWidth: true }
            Repeater {
                model: page.rpm.slice(0, 8)
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        Text { Layout.fillWidth: true; text: modelData.name; color: modelData.repo.includes("vabu") ? Theme.mint : Theme.paper; font.family: Theme.sans; font.pixelSize: 14; elide: Text.ElideRight }
                        Text { text: modelData.version; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11 }
                    }
                    DashLine { Layout.fillWidth: true }
                }
            }
            Text {
                visible: page.rpm.length > 8
                Layout.topMargin: 10
                text: "+ " + (page.rpm.length - 8) + " paket daha"
                color: Theme.muted; font.family: Theme.sans; font.pixelSize: 13
            }
            SectionLabel { Layout.topMargin: 18; text: "Flatpak uygulamaları · " + page.flat.length }
            DashLine { Layout.fillWidth: true }
            Repeater {
                model: page.flat.slice(0, 5)
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        Text { Layout.fillWidth: true; text: Apps.byId(modelData.id)?.name ?? modelData.id; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 14; elide: Text.ElideRight }
                        Text { text: modelData.version; color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11 }
                    }
                    DashLine { Layout.fillWidth: true }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 0
            SectionLabel { text: "Geri alma noktaları" }
            DashLine { Layout.fillWidth: true }
            Repeater {
                model: page.snapshots
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text { Layout.fillWidth: true; text: modelData.description || ("Nokta " + modelData.number); color: Theme.paper; font.family: Theme.sans; font.pixelSize: 14; elide: Text.ElideRight }
                            Text { text: (modelData.date || "") + " · #" + modelData.number; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 11 }
                        }
                        Text {
                            text: "Geri dön"
                            color: Theme.sky
                            font.family: Theme.sans; font.pixelSize: 13
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Ui.terminal(["sh", "-c", "vabu rollback " + modelData.number + "; echo; read -p 'Kapatmak için Enter…' _"])
                            }
                        }
                    }
                    DashLine { Layout.fillWidth: true }
                }
            }
            Text {
                visible: page.snapshots.length === 0
                Layout.topMargin: 12
                Layout.fillWidth: true
                text: "Henüz geri alma noktası yok. İlk dnf işleminde oluşur."
                color: Theme.muted; font.family: Theme.serif; font.italic: true; font.pixelSize: 18; wrapMode: Text.Wrap
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        DashLine { Layout.fillWidth: true }
        SettingRow {
            label: "Güncellemeleri arka planda indir"
            sub: "Her gün indirir; kurulum senin onayınla yapılır. Flatpak uygulamaları kendiliğinden güncellenir."
            Toggle {
                checked: page.autoDownload
                onToggled: {
                    Quickshell.execDetached(["pkexec", "systemctl", page.autoDownload ? "disable" : "enable", "--now", "vabu-update.timer"])
                    page.autoDownload = !page.autoDownload
                }
            }
        }
    }
}

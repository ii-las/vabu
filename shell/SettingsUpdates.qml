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
        implicitHeight: 92
        radius: Theme.radiusTile
        color: Qt.rgba(1, 1, 1, 0.035)
        border.width: 1
        border.color: page.total > 0 ? Theme.alpha(Theme.accent, 0.45) : Qt.rgba(1, 1, 1, 0.05)
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 16
            spacing: 14
            Rectangle {
                implicitWidth: 46; implicitHeight: 46
                radius: 14
                color: Theme.well
                Spinner { visible: page.checking; anchors.centerIn: parent; size: 22 }
                Icon {
                    visible: !page.checking
                    anchors.centerIn: parent
                    name: page.total > 0 ? "system_update_alt" : "check_circle"
                    size: 24
                    color: page.total > 0 ? Theme.paper : Theme.ok
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    Layout.fillWidth: true
                    text: page.checking ? "Denetleniyor" : page.total > 0 ? page.total + " güncelleme hazır" : "Her şey güncel"
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.2
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: page.total > 0 ? "Kurulumdan önce geri alma noktası alınır." : "Vabu her gün arka planda denetler."
                    color: Theme.muted
                    font.family: Theme.sans
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }
            PillButton { label: "Denetle"; icon: "refresh"; onClicked: page.check(true) }
            PillButton {
                visible: page.total > 0
                primary: true
                label: "Şimdi güncelle"
                onClicked: Ui.terminal(["sh", "-c", "vabu update; echo; read -p 'Kapatmak için Enter…' _"])
            }
        }
    }

    // Paket satırı: ad solda, sürüm sağda
    component PackageRow: Item {
        id: pr
        property string name: ""
        property string version: ""
        property bool ours: false
        Layout.fillWidth: true
        implicitHeight: 42
        Rectangle { visible: pr.y > 1; x: 16; width: parent.width - 32; height: 1; color: Theme.line }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12
            Text { Layout.fillWidth: true; text: pr.name; color: Theme.paper; font.family: Theme.sans; font.pixelSize: 14; font.weight: pr.ours ? Font.DemiBold : Font.Normal; elide: Text.ElideRight }
            Text { Layout.maximumWidth: pr.width * 0.5; text: pr.version; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 12; font.features: ({ "tnum": 1 }); elide: Text.ElideMiddle }
        }
    }

    Group {
        visible: page.rpm.length > 0
        title: "Sistem paketleri · " + page.rpm.length
        note: page.rpm.length > 8 ? "ve " + (page.rpm.length - 8) + " paket daha" : ""
        Repeater {
            model: page.rpm.slice(0, 8)
            delegate: PackageRow {
                required property var modelData
                name: modelData.name
                version: modelData.version
                ours: modelData.repo.includes("vabu")
            }
        }
    }
    Group {
        visible: page.flat.length > 0
        title: "Flatpak uygulamaları · " + page.flat.length
        Repeater {
            model: page.flat.slice(0, 6)
            delegate: PackageRow {
                required property var modelData
                name: Apps.byId(modelData.id)?.name ?? modelData.id
                version: modelData.version
            }
        }
    }

    Group {
        title: "Geri alma noktaları"
        note: "Her paket işleminden önce sistemin bir kopyası alınır. Bir güncelleme sorun çıkarırsa buradan önceki hâline dönebilirsin."
        Repeater {
            model: page.snapshots
            delegate: SettingRow {
                required property var modelData
                label: modelData.description || ("Nokta " + modelData.number)
                sub: (modelData.date || "") + " · #" + modelData.number
                PillButton {
                    implicitHeight: 36
                    label: "Geri dön"
                    icon: "history"
                    onClicked: Ui.terminal(["sh", "-c", "vabu rollback " + modelData.number + "; echo; read -p 'Kapatmak için Enter…' _"])
                }
            }
        }
        SettingRow {
            visible: page.snapshots.length === 0
            label: "Henüz geri alma noktası yok"
            sub: "İlk paket işleminde kendiliğinden oluşur"
        }
    }

    Group {
        SettingRow {
            label: "Güncellemeleri arka planda indir"
            sub: "Her gün indirilir; kurulum senin onayınla yapılır. Flatpak uygulamaları kendiliğinden güncellenir."
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

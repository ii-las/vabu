import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 18

    property var rpm: []              // [{name, version, repo}]
    property var flat: []             // [{id, version}]
    readonly property bool checking: dnfCheck.running || flatCheck.running
    property string rpmError: ""
    property string flatError: ""
    property string timerError: ""
    readonly property bool checkFailed: rpmError !== "" || flatError !== ""
    property bool autoDownload: true
    property var snapshots: []
    property var lastUpdate: null
    property string rebootState: "unknown"
    function refreshResult() { if (!resultProbe.running) resultProbe.running = true; if (!rebootProbe.running) rebootProbe.running = true }
    Process { id: resultProbe; command: ["/usr/libexec/vabu/update","status"]; stdout: StdioCollector { onStreamFinished: { try { page.lastUpdate = JSON.parse(text).result } catch(e) { page.lastUpdate = null } } } }
    Process { id: rebootProbe; command: ["/usr/libexec/vabu/system-check","reboot"]; stdout: StdioCollector { onStreamFinished: { try { page.rebootState = JSON.parse(text).reboot } catch(e) { page.rebootState = "unknown" } } } }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: page.refreshResult() }

    readonly property int total: rpm.length + flat.length

    function check(refresh) {
        if (checking) return
        rpmError = ""; flatError = ""
        rpm = []; flat = []
        dnfCheck.command = ["dnf", "check-upgrade", "-q", refresh ? "--refresh" : "-C"]
        dnfCheck.running = true
        flatCheck.running = true
    }
    Component.onCompleted: { check(false); timer.running = true; snaps.running = true; refreshResult() }

    Process {
        id: dnfCheck
        environment: ({ "LC_ALL": "C" })
        stderr: StdioCollector { id: rpmErr }
        onExited: code => {
            if (code !== 0 && code !== 100) {
                page.rpm = []
                page.rpmError = rpmErr.text.trim() || "Sistem güncellemeleri denetlenemedi."
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                page.rpm = text.split("\n").map(l => l.trim().split(/\s+/)).filter(p => p.length >= 3 && /\.(x86_64|aarch64|noarch|i686)$/.test(p[0]))
                    .map(p => ({ name: p[0].replace(/\.[^.]+$/, ""), version: p[1], repo: p[2] }))
                    .sort((a, b) => (b.repo.includes("vabu") - a.repo.includes("vabu")) || a.name.localeCompare(b.name))
            }
        }
    }
    Process {
        id: flatCheck
        environment: ({ "LC_ALL": "C" })
        stderr: StdioCollector { id: flatErr }
        onExited: code => {
            if (code !== 0) {
                page.flat = []
                page.flatError = flatErr.text.trim() || "Flatpak güncellemeleri denetlenemedi."
            }
        }
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

    Process {
        id: timerChange
        stderr: StdioCollector { id: timerErr }
        onExited: code => {
            page.timerError = code === 0 ? "" : (timerErr.text.trim() || "Zamanlayıcı değiştirilemedi.")
            timer.running = true
        }
    }

    // Özet
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 92
        radius: Theme.radiusTile
        color: Theme.group
        border.width: 1
        border.color: page.total > 0 ? Theme.alpha(Theme.accent, 0.45) : Theme.groupEdge
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
                    name: page.checkFailed ? "error" : page.total > 0 ? "system_update_alt" : "check_circle"
                    size: 24
                    color: page.checkFailed ? Theme.danger : page.total > 0 ? Theme.paper : Theme.ok
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text { textFormat: Text.PlainText;
                    Layout.fillWidth: true
                    text: page.checking ? Lang.t("Denetleniyor") : page.checkFailed ? Lang.t("Denetim tamamlanamadı") : page.total > 0 ? page.total + " güncelleme hazır" : Lang.t("Her şey güncel")
                    color: Theme.paper
                    font.family: Theme.sans
                    font.pixelSize: Math.round((18) * Config.textScale)
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.2
                    elide: Text.ElideRight
                }
                Text { textFormat: Text.PlainText;
                    Layout.fillWidth: true
                    visible: false
                    text: ""
                    color: Theme.muted
                    font.family: Theme.sans
                    font.pixelSize: Math.round((13) * Config.textScale)
                    elide: Text.ElideRight
                }
            }
            PillButton { label: Lang.t("Denetle"); icon: "refresh"; enabled: !page.checking; onClicked: page.check(true) }
            PillButton {
                visible: page.total > 0
                primary: true
                label: Lang.t("Şimdi güncelle")
                onClicked: Ui.terminal(["sh", "-c", "vabu update; echo; read -p 'Kapatmak için Enter…' _"])
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: text !== ""
        text: [page.rpmError, page.flatError, page.timerError].filter(x => x).join("\n")
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Theme.danger
        font.family: Theme.sans
        font.pixelSize: Math.round((13) * Config.textScale)
    }

    Group {
        title: Lang.t("Son güncelleme sonucu")
        note: page.lastUpdate ? Lang.t(({success:"Tamamlandı",failed:"Başarısız",interrupted:"Kesildi",running:"Çalışıyor"})[page.lastUpdate.state] || "Bilinmiyor") : Lang.t("Henüz kayıt yok")
        Repeater {
            model: page.lastUpdate?.phases ?? []
            delegate: SettingRow { required property var modelData; label: modelData.phase; sub: Lang.t("Çıkış kodu") + ": " + modelData.exitCode }
        }
        SettingRow { label: Lang.t("Yeniden başlatma"); sub: Lang.t(({required:"Öneriliyor", "not-required":"Gerekmiyor",unknown:"Denetlenemedi"})[page.rebootState] || "Denetlenemedi") }
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
            Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: pr.name; color: Theme.paper; font.family: Theme.sans; font.pixelSize: Math.round((14) * Config.textScale); font.weight: pr.ours ? Font.DemiBold : Font.Normal; elide: Text.ElideRight }
            Text { textFormat: Text.PlainText; Layout.maximumWidth: pr.width * 0.5; text: pr.version; color: Theme.muted; font.family: Theme.sans; font.pixelSize: Math.round((12) * Config.textScale); font.features: ({ "tnum": 1 }); elide: Text.ElideMiddle }
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
        title: Lang.t("Anlık görüntüler")
        note: Lang.t("Anlık görüntüler ayrı /boot bölümünü kapsamaz. Otomatik tam sistem geri alma henüz desteklenmiyor.")
        Repeater {
            model: page.snapshots
            delegate: SettingRow {
                required property var modelData
                label: modelData.description || ("Nokta " + modelData.number)
                sub: (modelData.date || "") + " · #" + modelData.number

            }
        }
        SettingRow {
            visible: page.snapshots.length === 0
            label: Lang.t("Henüz geri alma noktası yok")
        }
    }

    Group {
        SettingRow {
            label: Lang.t("Sistem paketlerini arka planda indir")
            sub: "RPM paketlerini indirir. Kullanıcı Flatpak güncellemelerinin ayrı zamanlayıcısı vardır."
            Toggle {
                enabled: !timerChange.running
                checked: page.autoDownload
                onToggled: {
                    page.timerError = ""
                    timerChange.command = ["pkexec", "systemctl", page.autoDownload ? "disable" : "enable", "--now", "vabu-update.timer"]
                    timerChange.running = true
                }
            }
        }
    }
}

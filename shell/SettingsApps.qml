import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: page
    spacing: 20

    property var repoOn: ({})         // depo kimliği -> true
    property bool flathub: false

    function refresh() { repos.running = true; remotes.running = true; for (const d of defaults) d.load() }
    Component.onCompleted: refresh()

    Process {
        id: repos
        command: ["dnf", "repolist", "--enabled", "-q"]
        stdout: StdioCollector {
            onStreamFinished: {
                const e = {}
                for (const l of text.split("\n").slice(1)) { const id = l.split(/\s+/)[0]; if (id) e[id] = true }
                page.repoOn = e
            }
        }
    }
    Process {
        id: remotes
        command: ["flatpak", "remotes", "--columns=name,options"]
        stdout: StdioCollector {
            onStreamFinished: page.flathub = text.split("\n").some(l => l.startsWith("flathub") && !l.includes("disabled"))
        }
    }
    Process { id: changer; onExited: page.refresh() }

    function setRepos(ids, isOn) {
        changer.command = ["pkexec", "dnf", "config-manager", "setopt"].concat(ids.map(id => id + ".enabled=" + (isOn ? 1 : 0)))
        changer.running = true
    }
    function setFlathub(isOn) {
        changer.command = isOn
            ? ["sh", "-c", "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; flatpak remote-modify --enable flathub 2>/dev/null; true"]
            : ["flatpak", "remote-modify", "--disable", "flathub"]
        changer.running = true
    }

    Group {
        title: Lang.t("Uygulama kaynakları")
        SettingRow {
            label: "Fedora"
            Chip { text: Lang.t("Her zaman açık"); kind: "ok" }
        }
        SettingRow {
            label: Lang.t("RPM Fusion (özgür)")
            Toggle {
                checked: page.repoOn["rpmfusion-free"] ?? false
                onToggled: page.setRepos(["rpmfusion-free", "rpmfusion-free-updates"], !checked)
            }
        }
        SettingRow {
            label: Lang.t("RPM Fusion (özgür olmayan)")
            Toggle {
                checked: page.repoOn["rpmfusion-nonfree"] ?? false
                onToggled: page.setRepos(["rpmfusion-nonfree", "rpmfusion-nonfree-updates"], !checked)
            }
        }
        SettingRow {
            label: "Vabu"
            Toggle { checked: page.repoOn["vabu"] ?? false; onToggled: page.setRepos(["vabu"], !checked) }
        }
        SettingRow {
            label: "Flathub"
            Toggle { checked: page.flathub; onToggled: page.setFlathub(!page.flathub) }
        }
    }

    // Varsayılan uygulamalar (gio mime)
    component DefaultApp: SettingRow {
        id: row
        property var mimes: []
        property var options: []      // [{id, name}]
        property string current: ""
        function load() { query.running = true }
        Process {
            id: query
            command: ["gio", "mime", row.mimes[0]]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = text.split("\n")
                    const def = (lines[0].match(/:\s*(\S+\.desktop)/) || [])[1] || ""
                    const ids = new Set()
                    for (const l of lines.slice(1)) { const m = l.trim().match(/^(\S+\.desktop)$/); if (m) ids.add(m[1]) }
                    if (def) ids.add(def)
                    row.current = def
                    row.options = [...ids].map(id => ({ id, name: (Apps.byId(id)?.name) ?? id.replace(/\.desktop$/, "") }))
                }
            }
        }
        Segmented {
            visible: row.options.length > 1
            options: row.options.slice(0, 3).map(o => o.name)
            currentIndex: row.options.slice(0, 3).findIndex(o => o.id === row.current)
            onPicked: i => {
                const id = row.options[i].id
                for (const m of row.mimes) Quickshell.execDetached(["gio", "mime", m, id])
                row.current = id
            }
        }
        Text { textFormat: Text.PlainText;
            visible: row.options.length <= 1
            text: row.options[0]?.name ?? "-"
            color: Theme.soft; font.family: Theme.sans; font.pixelSize: Math.round((14) * Config.textScale)
        }
    }

    property var defaults: [defWeb, defFiles, defImage, defVideo, defMusic, defText, defPdf]
    Group {
        title: Lang.t("Varsayılan uygulamalar")
        DefaultApp { id: defWeb;   label: Lang.t("Web tarayıcı");  mimes: ["x-scheme-handler/https", "x-scheme-handler/http", "text/html"] }
        DefaultApp { id: defFiles; label: Lang.t("Dosyalar");      mimes: ["inode/directory"] }
        DefaultApp { id: defImage; label: Lang.t("Resimler");      mimes: ["image/png", "image/jpeg", "image/webp"] }
        DefaultApp { id: defVideo; label: Lang.t("Videolar");      mimes: ["video/mp4", "video/x-matroska", "video/webm"] }
        DefaultApp { id: defMusic; label: Lang.t("Müzik");         mimes: ["audio/mpeg", "audio/flac", "audio/ogg"] }
        DefaultApp { id: defText; label: Lang.t("Metin");         mimes: ["text/plain"] }
        DefaultApp { id: defPdf;   label: "PDF";           mimes: ["application/pdf"] }
    }

    RowLayout {
        spacing: 10
        PillButton { label: Lang.t("Uygulama kur"); icon: "download"; primary: true; onClicked: Ui.run(["vabu-launcher", "--install"]) }
        PillButton {
            visible: Apps.byId("com.github.tchx84.Flatseal") !== null
            label: Lang.t("Flatpak izinleri")
            icon: "lock"
            onClicked: Apps.launch(Apps.byId("com.github.tchx84.Flatseal"))
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string query: ""
    property var results: []            // [{key, name, summary, sources:[{kind, ref}], installed}]
    property bool busy: dnfSearch.running || flatpakSearch.running
    property var states: ({})           // key -> "installing" | "done" | "error"

    property var rpmHits: []
    property var flatpakHits: []
    property var installedRpms: ({})
    property var installedFlatpaks: ({})

    readonly property var sourceInfo: ({
        "fedora":  { label: "FEDORA",     color: Theme.mint },
        "fusion":  { label: "RPM FUSION", color: Theme.peach },
        "vabu":    { label: "VABU",       color: Theme.rose },
        "flathub": { label: "FLATHUB",    color: Theme.sky }
    })

    // Uygulama olmayan paketleri gizle (kütüphane, geliştirme, dil paketleri…)
    function looksLikeApp(name) {
        return !/(-devel|-libs?|-debuginfo|-debugsource|-doc|-docs|-headers|-static|-common|-data|-langpack.*|-fonts?)$/.test(name)
            && !/^(lib|perl-|python3-|golang-|rust-|ghc-|nodejs-|php-|R-|texlive-|mingw|ocaml-|java-|js-)/.test(name)
    }

    function kindOf(repo) {
        if (repo.startsWith("rpmfusion")) return "fusion"
        if (repo.includes("vabu") || repo.includes("copr")) return "vabu"
        return "fedora"
    }

    function search(q) {
        query = q.trim()
        debounce.restart()
    }

    function run() {
        if (query.length < 2) { results = []; return }
        rpmHits = []
        flatpakHits = []
        dnfSearch.command = ["dnf", "repoquery", "--available", "--latest-limit=1", "-q",
            "--queryformat", "%{name}\t%{summary}\t%{repoid}\n", "*" + query + "*"]
        dnfSearch.running = true
        flatpakSearch.command = ["flatpak", "search", "--columns=application,name,description,remotes", query]
        flatpakSearch.running = true
    }

    function merge() {
        const q = query.toLowerCase()
        const map = {}
        for (const r of rpmHits) {
            const key = r.name.toLowerCase()
            map[key] = map[key] || { key, name: r.name, summary: r.summary, sources: [], installed: !!installedRpms[r.name] }
            map[key].sources.push({ kind: kindOf(r.repo), ref: r.name })
        }
        for (const f of flatpakHits) {
            const short = f.name.toLowerCase().replace(/\s+/g, "-")
            const key = map[short] ? short : f.id.toLowerCase()
            map[key] = map[key] || { key, name: f.name, summary: f.summary, sources: [], installed: false }
            map[key].name = f.name           // Flathub'daki görünen ad daha güzel
            if (!map[key].summary) map[key].summary = f.summary
            map[key].sources.push({ kind: "flathub", ref: f.id })
            if (installedFlatpaks[f.id]) map[key].installed = true
        }
        const rank = x => (x.name.toLowerCase() === q ? 0 : x.name.toLowerCase().startsWith(q) ? 1 : 2)
        results = Object.values(map).sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name)).slice(0, 8)
    }

    function install(item, source) {
        const src = source ?? item.sources[0]
        const s = Object.assign({}, states); s[item.key] = "installing"; states = s
        const cmd = src.kind === "flathub"
            ? ["flatpak", "install", "--user", "-y", "--noninteractive", "flathub", src.ref]
            : ["pkexec", "dnf", "install", "-y", src.ref]
        const proc = installer.createObject(root, { command: cmd, itemKey: item.key, itemName: item.name })
        proc.running = true
    }

    Component {
        id: installer
        Process {
            property string itemKey
            property string itemName
            onExited: (code) => {
                const s = Object.assign({}, root.states)
                s[itemKey] = code === 0 ? "done" : "error"
                root.states = s
                Quickshell.execDetached(["notify-send", "-a", "Vabu", "-i", "vabu-logo",
                    code === 0 ? itemName + " kuruldu" : itemName + " kurulamadı",
                    code === 0 ? "Başlatıcıdan açabilirsin." : "Ayrıntı için terminalde tekrar dene."])
                root.refreshInstalled()
                destroy()
            }
        }
    }

    function refreshInstalled() {
        rpmList.running = true
        flatpakList.running = true
    }

    Timer { id: debounce; interval: 280; onTriggered: root.run() }

    Process {
        id: dnfSearch
        stdout: StdioCollector {
            onStreamFinished: {
                root.rpmHits = text.split("\n").filter(l => l).map(l => {
                    const [name, summary, repo] = l.split("\t")
                    return { name, summary, repo: repo || "" }
                }).filter(r => r.name && root.looksLikeApp(r.name)).slice(0, 30)
                root.merge()
            }
        }
    }

    Process {
        id: flatpakSearch
        stdout: StdioCollector {
            onStreamFinished: {
                root.flatpakHits = text.split("\n").filter(l => l && !l.startsWith("No matches")).map(l => {
                    const [id, name, summary, remotes] = l.split("\t")
                    return { id, name, summary, remotes: remotes || "" }
                }).filter(f => f.id && f.remotes.includes("flathub")).slice(0, 20)
                root.merge()
            }
        }
    }

    Process {
        id: rpmList
        running: true
        command: ["rpm", "-qa", "--qf", "%{NAME}\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {}
                for (const n of text.split("\n")) if (n) m[n] = true
                root.installedRpms = m
            }
        }
    }

    Process {
        id: flatpakList
        running: true
        command: ["flatpak", "list", "--app", "--columns=application"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {}
                for (const n of text.split("\n")) if (n) m[n.trim()] = true
                root.installedFlatpaks = m
            }
        }
    }
}

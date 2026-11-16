pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string query: ""
    property var results: []            // [{key, name, summary, icon, sources:[{kind, ref}], installed}]
    property bool busy: (indexer.running && catalog.length === 0) || dnfSearch.running
    property var states: ({})           // key -> "installing" | "done" | "error"

    // AppStream kataloglarından çıkarılan yerel dizin (bkz. /usr/libexec/vabu/app-index)
    property var catalog: []
    property var rpmHits: []
    property var installedRpms: ({})
    property var installedFlatpaks: ({})

    readonly property var sourceInfo: ({
        "fedora":  { label: "Fedora",     color: Theme.sky },
        "fusion":  { label: "RPM Fusion", color: Theme.warn },
        "vabu":    { label: "Vabu",       color: Theme.paper },
        "flathub": { label: "Flathub",    color: Theme.ok }
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

    function isInstalled(sources) {
        return sources.some(s => s.kind === "flathub" ? !!installedFlatpaks[s.ref] : !!installedRpms[s.ref])
    }

    function search(q) {
        query = q.trim()
        if (catalog.length === 0 && !indexer.running) indexer.running = true
        debounce.restart()
    }

    function score(a, q) {
        const name = a.lower
        if (name === q) return 100
        if (name.startsWith(q)) return 80
        if (name.split(/[\s\-_.:]/).some(w => w.startsWith(q))) return 60
        if (name.includes(q)) return 40
        if (a.kw.includes(q)) return 25
        if (a.key.includes(q)) return 15
        if (a.summary.toLowerCase().includes(q)) return 8
        return 0
    }

    function run() {
        if (query.length < 2) { results = []; rpmHits = []; return }
        rpmHits = []
        merge()
        // Katalogda az sonuç varsa uygulama olmayan paketlere de bak; yalnızca önbellekten,
        // depo verisi indirmeden (sistem önbelleğini güncelleme zamanlayıcısı tazeler)
        if (results.length < 4 && query.length >= 3) {
            dnfSearch.command = ["dnf", "repoquery", "-C", "--available", "--latest-limit=1", "-q",
                "--queryformat", "%{name}\t%{summary}\t%{repoid}\n", "*" + query + "*"]
            dnfSearch.running = false
            dnfSearch.running = true
        }
    }

    function merge() {
        const q = query.toLowerCase()
        const found = catalog.map(a => ({ a, s: score(a, q) })).filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s || x.a.lower.localeCompare(y.a.lower))
            .slice(0, 8)
            .map(x => ({ key: x.a.key, name: x.a.name, summary: x.a.summary, icon: x.a.icon,
                         sources: x.a.sources, installed: isInstalled(x.a.sources) }))
        const taken = new Set()
        for (const r of found) for (const s of r.sources) if (s.kind !== "flathub") taken.add(s.ref)
        const extra = rpmHits.filter(r => !taken.has(r.name)).slice(0, Math.max(0, 8 - found.length)).map(r => ({
            key: "rpm:" + r.name, name: r.name, summary: r.summary, icon: "",
            sources: [{ kind: kindOf(r.repo), ref: r.name }], installed: !!installedRpms[r.name]
        }))
        results = found.concat(extra)
    }

    function parseCatalog(text) {
        const list = []
        for (const line of text.split("\n")) {
            if (!line) continue
            const [key, name, summary, icon, kw, src] = line.split("\t")
            if (!key || !name || !src) continue
            list.push({
                key, name, lower: name.toLowerCase(), summary: summary ?? "", icon: icon ?? "", kw: kw ?? "",
                sources: src.split(",").map(x => { const i = x.indexOf("="); return { kind: x.slice(0, i), ref: x.slice(i + 1) } })
            })
        }
        catalog = list
        if (query.length >= 2) merge()
    }

    function install(item, source) {
        const src = source ?? item.sources[0]
        const s = Object.assign({}, states); s[item.key] = "installing"; states = s
        const cmd = src.kind === "flathub"
            ? ["flatpak", "install", "-y", "--noninteractive", "flathub", src.ref]
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

    Timer { id: debounce; interval: 90; onTriggered: root.run() }

    FileView {
        id: catalogFile
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/vabu/apps.tsv"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseCatalog(text())
    }

    // Dizin açılıştan biraz sonra, kabuğu yavaşlatmadan tazelenir
    Process {
        id: indexer
        command: ["nice", "-n", "19", "/usr/libexec/vabu/app-index"]
        onExited: catalogFile.reload()
    }
    Timer { running: true; interval: 15000; onTriggered: indexer.running = true }

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
        id: rpmList
        running: true
        command: ["rpm", "-qa", "--qf", "%{NAME}\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {}
                for (const n of text.split("\n")) if (n) m[n] = true
                root.installedRpms = m
                if (root.query.length >= 2) root.merge()
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
                if (root.query.length >= 2) root.merge()
            }
        }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    property var launches: ({})     // id -> açılış sayısı

    function byId(id) {
        const low = id.toLowerCase()
        return all.find(e => e.id.toLowerCase() === low || e.id.toLowerCase() === low + ".desktop") ?? null
    }

    // Pencereden uygulamaya: app_id çoğu zaman .desktop adıyla aynıdır ama her zaman değil.
    // Quickshell pencerelerinin (Ayarlar, kurulum) app_id'si hep "org.quickshell"; onları başlıktan tanırız.
    property var windowCache: ({})
    function forWindow(appId, title) {
        if (!appId) return null
        const own = appId === "org.quickshell"
        const key = own ? appId + "|" + (title ?? "") : appId
        if (key in windowCache) return windowCache[key]
        const e = own ? (all.find(x => x.name === title || x.genericName === title) ?? null)
            : (byId(appId) ?? DesktopEntries.heuristicLookup(appId) ?? null)
        windowCache[key] = e
        return e
    }
    function iconFor(appId, title) {
        const e = forWindow(appId, title)
        return Quickshell.iconPath(e?.icon || appId || "application-x-executable", "application-x-executable")
    }
    function nameFor(appId, title) {
        const e = forWindow(appId, title)
        if (e) return e.name
        if (!appId) return ""
        const last = appId.split(".").pop().replace(/[-_]/g, " ")
        return last.charAt(0).toUpperCase() + last.slice(1)
    }
    onAllChanged: windowCache = ({})

    // Bu uygulamanın açık pencereleri
    function windowsOf(entry) {
        const id = entry.id.toLowerCase().replace(/\.desktop$/, "")
        return Niri.windows.filter(w => {
            const a = (w.app_id || "").toLowerCase()
            if (a === "org.quickshell") return forWindow(w.app_id, w.title) === entry
            return a === id || id.endsWith("." + a) || a.endsWith("." + id)
        })
    }
    // Açıksa penceresine git, değilse başlat
    function open(entry) {
        const w = windowsOf(entry)[0]
        if (w) Niri.focusWindow(w.id)
        else launch(entry)
    }

    readonly property var pinnedEntries: Config.pinned.map(id => byId(id)).filter(e => e)

    readonly property var frequent: all.slice()
        .sort((a, b) => (launches[b.id] ?? 0) - (launches[a.id] ?? 0) || a.name.localeCompare(b.name))
        .slice(0, 5)

    // Basit ama iyi hissettiren puanlama: ad başı > kelime başı > içerir > açıklama/anahtar kelime.
    function score(e, q) {
        const name = e.name.toLowerCase()
        if (name === q) return 100
        if (name.startsWith(q)) return 80
        if (name.split(/[\s\-_.]/).some(w => w.startsWith(q))) return 60
        if (name.includes(q)) return 40
        const extra = [e.genericName, e.comment, (e.keywords || []).join(" "), e.id].join(" ").toLowerCase()
        if (extra.includes(q)) return 20
        return 0
    }

    function search(query) {
        const q = query.trim().toLowerCase()
        if (!q) return frequent
        return all.map(e => ({ e, s: score(e, q) }))
            .filter(x => x.s > 0)
            .map(x => ({ e: x.e, s: x.s + Math.min(10, launches[x.e.id] ?? 0) }))
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .slice(0, 8)
            .map(x => x.e)
    }

    function launch(entry) {
        const l = Object.assign({}, launches)
        l[entry.id] = (l[entry.id] ?? 0) + 1
        launches = l
        store.setText(JSON.stringify(l))
        entry.execute()
    }

    FileView {
        id: store
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/vabu/launches.json"
        printErrors: false
        onLoaded: { try { root.launches = JSON.parse(text()) } catch (e) { root.launches = {} } }
    }

    Process {
        running: true
        command: ["mkdir", "-p", (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/vabu"]
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// niri ile konuşur: olay akışını dinler, çalışma alanı ve pencere durumunu tutar.
Singleton {
    id: root

    property var workspaces: []     // niri Workspace nesneleri (çıkış + sıra ile sıralı)
    property var windows: []        // niri Window nesneleri
    property bool available: false
    property bool overviewOpen: false
    property var kbNames: []
    property int kbIndex: 0

    readonly property var focusedWindow: windows.find(w => w.is_focused) ?? null
    readonly property string focusedTitle: focusedWindow ? (focusedWindow.title || focusedWindow.app_id || "") : ""
    readonly property string focusedOutput: (workspaces.find(w => w.is_focused) ?? {}).output ?? ""

    // Klavye düzeni kısaltması: "Turkish (F)" -> "TR", "English (US)" -> "EN"
    readonly property string kbShort: {
        const n = kbNames[kbIndex] ?? ""
        if (!n) return ""
        const map = { "turkish": "TR", "english": "EN", "german": "DE", "french": "FR", "spanish": "ES", "russian": "RU", "arabic": "AR", "italian": "IT" }
        const first = n.toLowerCase().split(/[\s(]/)[0]
        return map[first] ?? n.slice(0, 2).toUpperCase()
    }

    function workspacesOn(output) {
        return workspaces.filter(w => !output || w.output === output)
    }

    // Bir çalışma alanının kolonları, soldan sağa: [{ index, focused, windows: [pencere...] }]
    // niri 25.08+ her pencerenin şeritteki yerini verir; vermiyorsa açılış sırası kullanılır.
    function columnsFor(wsId) {
        const cols = {}
        let fallback = 1000
        for (const w of windows) {
            if (w.workspace_id !== wsId) continue
            const pos = w.layout && w.layout.pos_in_scrolling_layout
            // yüzen pencereler şeridin sonunda, kendi başlarına durur
            const col = w.is_floating || !pos ? ++fallback : pos[0]
            const row = pos ? pos[1] : 1
            if (!cols[col]) cols[col] = { index: col, focused: false, windows: [] }
            cols[col].windows.push({ win: w, row: row })
            if (w.is_focused) cols[col].focused = true
        }
        return Object.values(cols).sort((a, b) => a.index - b.index).map(c => ({
            index: c.index,
            focused: c.focused,
            windows: c.windows.sort((a, b) => a.row - b.row).map(x => x.win)
        }))
    }

    // Yan paneldeki satırlar. niri her ekranın sonunda boş bir alan tutar: o, yeni pencereler
    // için hazır bekleyen "yedek" alandır; içinde değilken ayrı, ince bir satır olarak gösterilir.
    function rowsFor(output) {
        const list = workspacesOn(output)
        return list.map((ws, i) => {
            const columns = columnsFor(ws.id)
            const count = columns.reduce((n, c) => n + c.windows.length, 0)
            const spare = count === 0 && !ws.name && i === list.length - 1
            return { ws: ws, columns: columns, count: count, spare: spare }
        })
    }

    function action(args) {
        Quickshell.execDetached(["niri", "msg", "action"].concat(args))
    }
    // Sıra numarası odaktaki ekrana göre yorumlandığı için önce o ekrana geçilir
    function focusWorkspace(ws) {
        if (ws.is_focused) return
        Quickshell.execDetached(["sh", "-c",
            "niri msg action focus-monitor \"$1\" && niri msg action focus-workspace \"$2\"",
            "sh", ws.output, String(ws.idx)])
    }
    function focusWindow(id) { action(["focus-window", "--id", String(id)]) }
    function closeWindow(id) { action(["close-window", "--id", String(id)]) }
    function toggleOverview() { action(["toggle-overview"]) }
    function quit() { action(["quit", "--skip-confirmation"]) }
    function powerOffMonitors() { action(["power-off-monitors"]) }

    function patchWindow(id, fn) {
        root.windows = root.windows.map(w => w.id === id ? fn(Object.assign({}, w)) : w)
    }
    function patchWorkspace(id, fn) {
        root.workspaces = root.workspaces.map(w => w.id === id ? fn(Object.assign({}, w)) : w)
    }

    function handle(line) {
        let ev
        try { ev = JSON.parse(line) } catch (e) { return }
        root.available = true

        if (ev.WorkspacesChanged) {
            root.workspaces = ev.WorkspacesChanged.workspaces.slice().sort((a, b) =>
                (a.output || "").localeCompare(b.output || "") || a.idx - b.idx)
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id
            const focused = ev.WorkspaceActivated.focused
            const out = (root.workspaces.find(w => w.id === id) || {}).output
            root.workspaces = root.workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === out ? w.id === id : w.is_active,
                is_focused: focused ? w.id === id : w.is_focused
            }))
        } else if (ev.WorkspaceActiveWindowChanged) {
            const c = ev.WorkspaceActiveWindowChanged
            patchWorkspace(c.workspace_id, w => { w.active_window_id = c.active_window_id; return w })
        } else if (ev.WorkspaceUrgencyChanged) {
            const c = ev.WorkspaceUrgencyChanged
            patchWorkspace(c.id, w => { w.is_urgent = c.urgent; return w })
        } else if (ev.WindowsChanged) {
            root.windows = ev.WindowsChanged.windows
        } else if (ev.WindowOpenedOrChanged) {
            const win = ev.WindowOpenedOrChanged.window
            let list = root.windows.filter(w => w.id !== win.id)
            if (win.is_focused) list = list.map(w => Object.assign({}, w, { is_focused: false }))
            list.push(win)
            root.windows = list
        } else if (ev.WindowClosed) {
            const id = ev.WindowClosed.id
            root.windows = root.windows.filter(w => w.id !== id)
        } else if (ev.WindowFocusChanged) {
            const id = ev.WindowFocusChanged.id
            root.windows = root.windows.map(w => Object.assign({}, w, { is_focused: w.id === id }))
        } else if (ev.WindowUrgencyChanged) {
            const c = ev.WindowUrgencyChanged
            patchWindow(c.id, w => { w.is_urgent = c.urgent; return w })
        } else if (ev.WindowLayoutsChanged) {
            const changes = new Map(ev.WindowLayoutsChanged.changes)
            root.windows = root.windows.map(w => changes.has(w.id)
                ? Object.assign({}, w, { layout: changes.get(w.id) }) : w)
        } else if (ev.KeyboardLayoutsChanged) {
            root.kbNames = ev.KeyboardLayoutsChanged.keyboard_layouts.names
            root.kbIndex = ev.KeyboardLayoutsChanged.keyboard_layouts.current_idx
        } else if (ev.KeyboardLayoutSwitched) {
            root.kbIndex = ev.KeyboardLayoutSwitched.idx
        } else if (ev.OverviewOpenedOrClosed) {
            root.overviewOpen = ev.OverviewOpenedOrClosed.is_open
        }
    }

    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
        onExited: {
            root.available = false
            retry.start()
        }
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: stream.running = true
    }
}

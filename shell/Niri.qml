pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []     // niri Workspace nesneleri (çıkış + sıra ile sıralı)
    property var windows: []        // niri Window nesneleri
    property bool available: false

    readonly property var focusedWindow: windows.find(w => w.is_focused) ?? null
    readonly property string focusedTitle: focusedWindow ? (focusedWindow.title || focusedWindow.app_id || "") : ""

    function workspacesOn(output) {
        return workspaces.filter(w => !output || w.output === output)
    }

    // Bir çalışma alanının kolonları: [{index, width, focused, count}]
    // niri 25.08+ pencere düzenini (pos_in_scrolling_layout, tile_size) verir;
    // daha eski sürümlerde her pencere bir kolon sayılır.
    function columnsFor(wsId) {
        const cols = {}
        let fallback = 0
        for (const w of windows) {
            if (w.workspace_id !== wsId || w.is_floating) continue
            const lay = w.layout
            const pos = lay && lay.pos_in_scrolling_layout
            const idx = pos ? pos[0] : ++fallback
            const width = lay && lay.tile_size ? lay.tile_size[0] : 1
            if (!cols[idx]) cols[idx] = { index: idx, width: width, focused: false, count: 0 }
            cols[idx].count += 1
            cols[idx].width = Math.max(cols[idx].width, width)
            if (w.is_focused) cols[idx].focused = true
        }
        return Object.values(cols).sort((a, b) => a.index - b.index)
    }

    function action(args) {
        Quickshell.execDetached(["niri", "msg", "action"].concat(args))
    }
    function focusWorkspace(ws) { action(["focus-workspace", String(ws.idx)]) }
    function focusWindow(id) { action(["focus-window", "--id", String(id)]) }
    function quit() { action(["quit", "--skip-confirmation"]) }
    function powerOffMonitors() { action(["power-off-monitors"]) }

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
        } else if (ev.WindowLayoutsChanged) {
            const changes = new Map(ev.WindowLayoutsChanged.changes)
            root.windows = root.windows.map(w => changes.has(w.id)
                ? Object.assign({}, w, { layout: changes.get(w.id) }) : w)
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
